#!/bin/sh
# backlight-probe.sh — inspect the backlight path, and A/B the kernel's opinion
# of it. Read-only by default; the mutating modes are opt-in and reversible.
#
# Why: brightnessctl already reports 1515/1515 (100% duty) on this T480, so the
# remaining candidates are not "software settings" at all:
#
#   - DPST/CABC: content-adaptive backlight control, if the i915 driver has it
#     enabled, dims dark scenes after the compositor is done. It looks exactly
#     like "the panel is too dim" and is invisible in every userspace knob.
#   - acpi_backlight=: the kernel picks between the native intel_backlight
#     interface and ACPI video/vendor ones. A VBT-clamped native range can
#     report a lower max_brightness than the panel can actually do, so the
#     alternative interface is worth one boot to compare.
#   - systemd-backlight: restores the *last saved* percentage at boot, before
#     login. The saved file here says 36%, which is why the greeter and the
#     first seconds of the session are dim regardless of light.sh.
#
#   sudo backlight-probe.sh                 # read-only report
#   sudo backlight-probe.sh --fix-saved     # make the greeter boot at 100%
#   sudo backlight-probe.sh --grub-test acpi_backlight=native
#   sudo backlight-probe.sh --grub-revert
#
# --grub-test backs up /etc/default/grub and needs a reboot to take effect;
# --grub-revert restores the newest backup and regenerates grub.cfg.

set -u

BACKLIGHT_DIR=/sys/class/backlight
DEV="$(ls "$BACKLIGHT_DIR" 2>/dev/null | head -1)"
SAVED_GLOB='/var/lib/systemd/backlight/*backlight*intel*'
GRUB=/etc/default/grub

root() { [ "$(id -u)" -eq 0 ]; }

hr() { printf '%s\n' "------------------------------------------------------------"; }

show_state() {
    hr
    printf 'panel: '
    tr -d '\0' </sys/class/dmi/id/product_name 2>/dev/null
    printf '  kernel: %s\n' "$(uname -r)"
    hr
    if [ -z "$DEV" ]; then
        echo "no /sys/class/backlight device"
    else
        echo "backlight device: $DEV"
        for f in brightness actual_brightness max_brightness type; do
            printf '  %-18s %s\n' "$f" "$(cat "$BACKLIGHT_DIR/$DEV/$f" 2>/dev/null)"
        done
        cur=$(cat "$BACKLIGHT_DIR/$DEV/brightness" 2>/dev/null)
        max=$(cat "$BACKLIGHT_DIR/$DEV/max_brightness" 2>/dev/null)
        [ -n "${cur:-}" ] && [ -n "${max:-}" ] && [ "$max" -gt 0 ] &&
            printf '  duty               %s%%\n' "$((cur * 100 / max))"
    fi
    for f in $SAVED_GLOB; do
        [ -r "$f" ] && printf '  systemd saved      %s  (%s)\n' "$(cat "$f")" "$f"
    done
    printf '  kernel cmdline     %s\n' "$(cat /proc/cmdline)"
    hr

    echo "i915 debugfs (DPST/CABC = content-adaptive dimming):"
    if grep -q ' /sys/kernel/debug ' /proc/mounts 2>/dev/null; then
        if [ ! -r /sys/kernel/debug/dri ]; then
            echo "  debugfs is mounted but root-only — re-run with sudo to see DPST/CABC knobs"
        else
            found=0
            for d in /sys/kernel/debug/dri/*/; do
                [ -d "$d" ] || continue
                for f in "$d"*; do
                    case "$(basename "$f")" in
                    *dpst*|*cabc*|*blc*|*backlight*|*edp*) found=1; printf '  %s\n' "$f" ;;
                    esac
                done
            done
            [ "$found" -eq 0 ] && echo "  no dpst/cabc/blc knobs exposed (usually means DPST is not compiled in / not enabled)"
        fi
    else
        echo "  debugfs not mounted (mount -t debugfs none /sys/kernel/debug)"
    fi
    for f in /sys/kernel/debug/dri/*/i915_dpst_*; do
        [ -r "$f" ] && printf '  %s = %s\n' "$f" "$(cat "$f" 2>/dev/null)"
    done
    hr

    echo "kernel backlight messages:"
    { journalctl -k -b 2>/dev/null || dmesg 2>/dev/null; } |
        grep -iE 'backlight|pwm|dpst|cabc|blc_' | tail -20 | sed 's/^/  /'
    hr

    if [ -n "${DISPLAY:-}" ] && [ -x "${0%/*}/lut.py" ]; then
        echo "userspace LUT / CTM:"
        "${0%/*}/lut.py" show | sed 's/^/  /'
        hr
    fi

    echo "verdict:"
    cur=$(cat "$BACKLIGHT_DIR/$DEV/brightness" 2>/dev/null || echo 0)
    max=$(cat "$BACKLIGHT_DIR/$DEV/max_brightness" 2>/dev/null || echo 0)
    if [ "$max" -gt 0 ] && [ "$cur" -ge "$max" ]; then
        echo "  hardware backlight is already at 100% duty — nothing above it in"
        echo "  software. Any remaining gain must be a panel swap, or the LUT"
        echo "  curve from light.sh (perceived, not measured, luminance)."
    fi
    if grep -qE 'acpi_backlight' /proc/cmdline; then
        echo "  acpi_backlight override is active: $(tr ' ' '\n' </proc/cmdline | grep acpi_backlight)"
    else
        echo "  no acpi_backlight override (kernel used its default selection)."
    fi
}

fix_saved() {
    root || { echo "--fix-saved needs root" >&2; exit 1; }
    cur=$(cat "$BACKLIGHT_DIR/$DEV/brightness")
    for f in $SAVED_GLOB; do
        [ -w "$f" ] || continue
        printf '%s' "$cur" >"$f"
        echo "wrote $cur to $f (greeter will boot at $(($(cat "$f") * 100 / $(cat "$BACKLIGHT_DIR/$DEV/max_brightness")))%)"
    done
}

grub_test() {
    param="${1:-}"
    [ -n "$param" ] || { echo "usage: --grub-test acpi_backlight=native" >&2; exit 2; }
    root || { echo "--grub-test needs root" >&2; exit 1; }
    [ -f "$GRUB" ] || { echo "$GRUB not found (systemd-boot?)" >&2; exit 1; }
    bak="$GRUB.bak.$(date +%Y%m%d_%H%M%S)"
    cp -a "$GRUB" "$bak" || exit 1
    if grep -q -- "$param" "$GRUB"; then
        echo "$param already present; nothing to do"
        return 0
    fi
    sed -i "s/^\(GRUB_CMDLINE_LINUX_DEFAULT=\"[^\"]*\)\"/\1 $param\"/" "$GRUB"
    command -v update-grub >/dev/null 2>&1 && update-grub >/dev/null || grub-mkconfig -o /boot/grub/grub.cfg
    echo "added '$param' to $GRUB (backup: $bak)"
    echo "reboot, then compare:"
    echo "  cat /sys/class/backlight/*/max_brightness"
    echo "  brightnessctl -m"
    echo "revert with: sudo $0 --grub-revert"
}

grub_revert() {
    root || { echo "--grub-revert needs root" >&2; exit 1; }
    bak=$(ls -1t "$GRUB".bak.* 2>/dev/null | head -1)
    [ -n "$bak" ] || { echo "no $GRUB.bak.* found" >&2; exit 1; }
    cp -a "$bak" "$GRUB"
    command -v update-grub >/dev/null 2>&1 && update-grub >/dev/null || grub-mkconfig -o /boot/grub/grub.cfg
    echo "restored $GRUB from $bak and regenerated grub.cfg"
}

case "${1:-}" in
"") show_state ;;
--fix-saved) fix_saved ;;
--grub-test) grub_test "${2:-}" ;;
--grub-revert) grub_revert ;;
*) echo "usage: $0 [--fix-saved|--grub-test PARAM|--grub-revert]" >&2; exit 2 ;;
esac
