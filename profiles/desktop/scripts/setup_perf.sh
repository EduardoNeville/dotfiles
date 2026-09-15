#!/usr/bin/env bash
# setup_perf.sh — storage/boot tuning for the desktop profile on a spinning disk.
#
# hydra's /, /var, /tmp, swap and /home all live on one 5400 rpm SATA disk
# (Toshiba MQ01ABD100M, /sys/block/sda/queue/rotational = 1) and the M.2 NVMe
# slot is empty, so every small-file read costs a head seek. These cuts remove
# the worst of it — and are pointless once root is on an SSD, hence the
# rotational guard.
#
#   1. /tmp     -> tmpfs   (today a 2.8G ext4 partition on the HDD)
#   2. ~/.cache -> tmpfs   (1.1G of browser/Mesa/nvim small-file I/O)
#   3. noatime on /, /var, /home
#   4. e2scrub_reap.service off  (25.7s of every boot scrubbing the HDD)
#   5. docker/libvirt daemons off at boot — their .socket units stay enabled,
#      so `docker` and `virsh` still start them on demand (verified enabled)
#
# 1-3 land at the next boot. Never mount tmpfs over a live /tmp: the X socket
# and the tmux server socket live there. noatime is additionally applied live
# with a remount, which is safe.
#
# Reversal: fstab edits are tagged and the original /tmp line is kept commented
# out; a timestamped backup is written; services are disabled, not masked.
#
#   setup_perf.sh            — apply
#   setup_perf.sh --dry-run  — print the fstab that would be written; change nothing

set -u

RUN_USER="${SUDO_USER:-$(id -un)}"
USER_HOME="$(getent passwd "$RUN_USER" | cut -d: -f6)"
CACHE_DIR="$USER_HOME/.cache"
FSTAB=/etc/fstab
BACKUP="$FSTAB.dotfiles-$(date +%Y%m%d_%H%M%S).bak"
DRY_RUN=0
[ "${1:-}" = "--dry-run" ] && DRY_RUN=1

# ── Rotational guard ─────────────────────────────────────────
root_src="$(findmnt -no SOURCE /)"
root_disk="/dev/$(basename "$(lsblk -no PKNAME "$root_src" 2>/dev/null || echo "$root_src")")"
rotational="$(cat "/sys/block/$(basename "$root_disk")/queue/rotational" 2>/dev/null || echo 1)"

# ── fstab transformation (pure: source in, new fstab on stdout) ──
build_fstab() {
    awk -v rot="$rotational" -v uid="$(id -u "$RUN_USER")" -v gid="$(id -g "$RUN_USER")" \
        -v cache="$CACHE_DIR" '
        /^[[:space:]]*#/ { print; next }
        NF < 4            { print; next }
        {
            mp = $2; fs = $3; opts = $4
            if (mp == "/tmp" && fs == "tmpfs") { print; next }
            if (mp == cache)                   { print; next }
            if (rot != "1")                    { print; next }
            if (mp == "/tmp") {
                print "# /tmp: moved to tmpfs by dotfiles profiles/desktop/scripts/setup_perf.sh;"
                print "# the partition below is kept (unmounted) for a future SSD layout."
                print "#" $0
                print "tmpfs /tmp tmpfs rw,nosuid,nodev,noatime,size=8G,nofail 0 0"
                next
            }
            if (mp == "/" || mp == "/var" || mp == "/home") {
                if (opts !~ /(^|,)noatime(,|$)/) opts = opts ",noatime"
                printf "%s %s %s %s %s %s\n", $1, $2, $3, opts, $5, $6
                next
            }
            print
        }
        END {
            if (rot == "1")
                printf "tmpfs %s tmpfs rw,nosuid,nodev,noatime,uid=%s,gid=%s,mode=0700,size=4G,nofail 0 0\n", cache, uid, gid
        }' "$FSTAB"
}

new_fstab="$(build_fstab)"

echo "root disk: $root_disk (rotational=$rotational)"
if [ "$rotational" = "1" ]; then
    echo "  → spinning disk: /tmp and $CACHE_DIR will be tmpfs, noatime everywhere"
else
    echo "  → SSD/flash root: tmpfs conversions skipped (only noatime + boot trims)"
fi
echo

if [ "$DRY_RUN" = "1" ]; then
    echo "=== /etc/fstab after transformation (dry run, nothing written) ==="
    printf '%s\n' "$new_fstab"
    echo "=== diff ==="
    diff <(printf '%s\n' "$new_fstab") "$FSTAB" || true
    echo "=== services that would be disabled ==="
    echo "  e2scrub_reap.service docker.service libvirtd.service virtlogd.service virtlockd.service"
    exit 0
fi

# ── 1. fstab ─────────────────────────────────────────────────
if ! diff -q <(printf '%s\n' "$new_fstab") "$FSTAB" >/dev/null; then
    sudo cp -a "$FSTAB" "$BACKUP"
    printf '%s\n' "$new_fstab" > /tmp/fstab.new
    sudo install -m 644 -o root -g root /tmp/fstab.new "$FSTAB"
    rm -f /tmp/fstab.new
    sudo systemctl daemon-reload
    echo "  ✓ $FSTAB updated (backup: $BACKUP)"
else
    echo "  ✓ $FSTAB already up to date"
fi

# ── 2. noatime now (remount is safe; tmpfs waits for reboot) ──
for m in / /var /home; do
    if findmnt -no OPTIONS "$m" | grep -q noatime; then
        echo "  ✓ $m already noatime"
    elif sudo mount -o remount,noatime "$m"; then
        echo "  ✓ $m remounted noatime"
    else
        echo "  ! $m remount failed (takes effect at next boot)"
    fi
done

# ── 3. boot trims ────────────────────────────────────────────
# The .socket units stay enabled, so docker/virsh still start their daemons on
# first use — only the boot-time cost goes away.
sudo systemctl enable docker.socket libvirtd.socket virtlogd.socket virtlockd.socket 2>/dev/null || true
for u in e2scrub_reap.service docker.service libvirtd.service virtlogd.service virtlockd.service; do
    if systemctl is-enabled "$u" >/dev/null 2>&1; then
        sudo systemctl disable "$u" >/dev/null 2>&1 && echo "  ✓ $u disabled at boot" || echo "  ! $u disable failed"
    else
        echo "  ✓ $u already disabled"
    fi
done

echo
echo "Done. /tmp and $CACHE_DIR become tmpfs at the next boot (they must not be"
echo "mounted over a live /tmp — the X and tmux sockets live there)."
