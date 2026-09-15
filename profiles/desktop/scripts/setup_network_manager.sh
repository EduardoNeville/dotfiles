#!/usr/bin/env bash
# setup_network_manager.sh — make NetworkManager own the wired NIC, so that
# plugging in a cable switches the machine onto it (and unplugging falls back).
#
# Why this is needed
#   The Debian installer writes a DHCP stanza for the ethernet device into
#   /etc/network/interfaces, and NetworkManager is told not to touch ifupdown's
#   devices (NetworkManager.conf: [ifupdown] managed=false). Consequences:
#     - the wire is brought up by ifupdown with route metric 1000+ifindex (1002
#       here), while wifi keeps NetworkManager's 600 — lower metric wins, so the
#       cable can be live and still not carry traffic (whichever default route
#       happens to exist decides, which is order-dependent);
#     - ifupdown reacts to the *device* appearing, never to a *cable* being
#       plugged, so plugging in after boot is not an event for anyone;
#     - `nmcli device set <dev> managed yes` cannot override it: the ifupdown
#       plugin re-asserts unmanaged.
#
# What it does (both idempotent; a timestamped backup of the file is kept)
#   A. comments the ifupdown DHCP stanza(s) out, force-downs them so no leftover
#      address or dhclient survives, then restarts NetworkManager. NM then owns
#      the device, creates "Wired connection 1" (autoconnect, route-metric 100
#      against wifi's 600) and watches carrier state: cable in → wire preferred,
#      cable out → wifi takes over. Wifi stays connected as a fallback.
#   C. installs /etc/NetworkManager/dispatcher.d/90-prefer-wired, which brings
#      wifi down while the wire is up and back up when it goes — for "one active
#      link only" rather than "wifi as fallback".
#
# Static stanzas are left alone and reported: converting a fixed address into a
# NetworkManager profile is a decision, not a fix.
#
#   setup_network_manager.sh            — apply A + C
#   setup_network_manager.sh --dry-run  — show the /etc/network/interfaces diff
#                                         and the dispatcher that would be
#                                         installed; change nothing, no sudo
#
# Rollback: restore the backup path printed below, delete the dispatcher, then
# `sudo systemctl restart NetworkManager`.

set -u

IFACES="${IFACES:-/etc/network/interfaces}"
DISPATCHER_SRC="$(dirname "$(readlink -f "$0")")/networkmanager-90-prefer-wired.sh"
DISPATCHER_DST=/etc/NetworkManager/dispatcher.d/90-prefer-wired
DRY_RUN=0
[ "${1:-}" = "--dry-run" ] && DRY_RUN=1

command -v nmcli >/dev/null 2>&1 || { echo "NetworkManager not installed — skipping"; exit 0; }
[ -f "$IFACES" ] || { echo "no $IFACES — nothing to do"; exit 0; }

# ── which devices to hand over ───────────────────────────────
static_devs="$(awk '/^[[:space:]]*iface[[:space:]]/ && $0 ~ /inet[[:space:]]+static/ { print $2 }' "$IFACES")"
if [ -n "$static_devs" ]; then
    echo "  ! static stanza(s) for: $(echo "$static_devs" | tr '\n' ' ')"
    echo "    leaving $IFACES untouched — move those to NetworkManager by hand, then re-run."
    echo "    (dispatcher install skipped too, so the two steps stay in sync)"
    exit 0
fi

handover="$(awk '/^[[:space:]]*iface[[:space:]]/ && $0 ~ /inet[[:space:]]+(dhcp|auto)/ && $2 != "lo" { print $2 }' "$IFACES")"

if [ -n "$handover" ]; then
    echo "→ handing these devices to NetworkManager: $(echo "$handover" | tr '\n' ' ')"
    printf '%s\n' "$handover" | awk '
        NR == FNR { wanted[$1] = 1; next }
        /^[[:space:]]*(auto|allow-hotplug|iface)[[:space:]]/ {
            dev = $2
            if (dev in wanted) {
                if (!(dev in seen)) {
                    print "# dotfiles: NetworkManager owns " dev \
                          " (profiles/desktop/scripts/setup_network_manager.sh)"
                    seen[dev] = 1
                }
                print "#" $0
                next
            }
        }
        { print }
    ' - "$IFACES" >/tmp/interfaces.new
else
    echo "  ✓ no ifupdown DHCP stanza left to hand over"
fi

# ── dry run: show everything, touch nothing, never call sudo ──
if [ "$DRY_RUN" = 1 ]; then
    if [ -n "$handover" ]; then
        echo "--- $IFACES after transformation (dry run) ---"
        diff "$IFACES" /tmp/interfaces.new || true
        rm -f /tmp/interfaces.new
    fi
    echo "--- would install $DISPATCHER_DST from $DISPATCHER_SRC ---"
    [ -r "$DISPATCHER_SRC" ] && sed -n '1,12p' "$DISPATCHER_SRC" || echo "  ! $DISPATCHER_SRC missing"
    echo "--- would then run: ifdown --force <dev...>; systemctl restart NetworkManager ---"
    exit 0
fi

# ── A. hand the device(s) over ───────────────────────────────
if [ -n "$handover" ]; then
    backup="$IFACES.bak-dotfiles-$(date +%Y%m%d_%H%M%S)"
    sudo cp -a "$IFACES" "$backup"
    sudo install -m 644 -o root -g root /tmp/interfaces.new "$IFACES"
    rm -f /tmp/interfaces.new
    echo "  ✓ stanzas commented out (backup: $backup)"

    for dev in $handover; do
        # --force: deconfigure even though the file no longer lists the device.
        # This releases the ifupdown address and stops its dhclient, so NM does
        # not inherit a foreign address.
        sudo ifdown --force "$dev" >/dev/null 2>&1 || true
        echo "  ✓ ifupdown released $dev"
    done

    sudo systemctl restart NetworkManager
    echo "  ✓ NetworkManager restarted"
fi

# ── C. wifi off while the wire is up ─────────────────────────
if [ -r "$DISPATCHER_SRC" ]; then
    sudo install -m 755 -o root -g root "$DISPATCHER_SRC" "$DISPATCHER_DST"
    echo "  ✓ installed $DISPATCHER_DST (wifi down while wired, back when unplugged)"
else
    echo "  ! $DISPATCHER_SRC missing — dispatcher not installed"
fi

# ── verify ───────────────────────────────────────────────────
echo
echo "=== current state ==="
nmcli device status 2>/dev/null | grep -E "DEVICE|ethernet|wifi"
echo "=== default routes (ethernet should be the lower metric) ==="
ip route show default
echo "=== which link carries traffic ==="
ip route get 1.1.1.1 2>/dev/null | head -1
echo
echo "Plug/unplug the cable and re-run these three to confirm the switch."
