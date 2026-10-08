#!/bin/sh
# battery_notify.sh — notify when the battery crosses a level.
#
#   battery_notify.sh                                   # real readings (timer)
#   battery_notify.sh --percent 25 --state discharging   # test override
#   battery_notify.sh --dry-run --percent 81 --state charging
#
# Warns once when discharging below 30%, 20% and 10%, and once when charging
# above 80%. The last notified level per direction is remembered in
# $XDG_STATE_HOME/battery-notify, so hovering at 30% does not re-notify;
# climbing above 32% (or falling below 78%) re-arms it, which is what makes a
# charge cycle or a battery swap behave.
#
# The percentage comes from upower's DisplayDevice — the combined reading for
# this laptop's two batteries (BAT0 internal + BAT1) — not from a single
# /sys/class/power_supply entry, which would ignore one of them.
#
# Runs as a systemd *user* service, so it has no session environment: the
# session bus address is derived from XDG_RUNTIME_DIR when it is missing
# (notify-send is a pure D-Bus client; dunst owns the display).
#
# --dry-run prints what it would send and skips notify-send, but still exercises
# the state file, so threshold sequences can be tested for real.

set -u

LOW_LEVELS="30 20 10"   # descending; the tightest one the level is under wins
HIGH_LEVEL=80
HIGH_REARM=78           # below this the >80 warning may fire again
LOW_REARM=32            # at/above this the <30 warning may fire again

STATE_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/battery-notify"
DRY_RUN=0
percent=""
charge_state=""

while [ $# -gt 0 ]; do
    case "$1" in
        --percent) percent="${2:-}"; shift 2 || shift ;;
        --state)   charge_state="${2:-}"; shift 2 || shift ;;
        --dry-run) DRY_RUN=1; shift ;;
        *) echo "usage: $0 [--dry-run] [--percent N] [--state charging|discharging|full]" >&2; exit 2 ;;
    esac
done

# ── read the battery unless overridden ───────────────────────
remaining=""
if [ -z "$percent" ]; then
    dev="$(upower -e 2>/dev/null | grep -m1 DisplayDevice)"
    [ -n "$dev" ] || { echo "upower reports no DisplayDevice; nothing to do"; exit 0; }
    info="$(upower -i "$dev" 2>/dev/null)"
    percent="$(printf '%s\n' "$info" | sed -n 's/.*percentage:[[:space:]]*\([0-9]*\).*/\1/p' | head -1)"
    [ -n "$charge_state" ] || charge_state="$(printf '%s\n' "$info" | sed -n 's/.*state:[[:space:]]*\([a-z-]*\).*/\1/p' | head -1)"
    remaining="$(printf '%s\n' "$info" | sed -n 's/.*time to \(empty\|full\):[[:space:]]*\(.*\)$/\2/p' | head -1)"
fi

case "$percent" in
    ''|*[!0-9]*) echo "cannot determine battery percentage" >&2; exit 1 ;;
esac

last_low="$(sed -n 's/^low=//p' "$STATE_FILE" 2>/dev/null | head -1)"
last_high="$(sed -n 's/^high=//p' "$STATE_FILE" 2>/dev/null | head -1)"

save_state() {
    mkdir -p "$(dirname "$STATE_FILE")"
    printf 'low=%s\nhigh=%s\n' "$1" "$2" >"$STATE_FILE"
}

# notify <replace-id> <urgency> <icon> <summary> [extra text]
notify() {
    _id="$1" _urgency="$2" _icon="$3" _summary="$4" _extra="${5:-}"
    if [ "$DRY_RUN" = 1 ]; then
        echo "would notify [$_urgency, %$percent] $_summary${_extra:+ — $_extra}"
        return 0
    fi
    command -v notify-send >/dev/null 2>&1 || { echo "notify-send missing" >&2; return 1; }
    : "${DBUS_SESSION_BUS_ADDRESS:=unix:path=${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/bus}"
    export DBUS_SESSION_BUS_ADDRESS
    notify-send -r "$_id" -u "$_urgency" -i "$_icon" -h int:value:"$percent" \
        "$_summary" "${_extra:-Battery at ${percent}%.}"
}

# ── discharging: warn once per level crossed ─────────────────
if [ "$charge_state" = "discharging" ]; then
    level=""
    for c in $LOW_LEVELS; do
        [ "$percent" -lt "$c" ] && level="$c"
    done
    if [ -n "$level" ] && [ "$level" != "$last_low" ]; then
        case "$level" in
            10) notify 7004 critical battery-caution-symbolic \
                    "Battery critical: ${percent}%" "Plug in now${remaining:+, $remaining}." ;;
            20) notify 7003 normal battery-level-20-symbolic \
                    "Battery low: ${percent}%" "20% left${remaining:+, $remaining}." ;;
            *)  notify 7002 normal battery-level-30-symbolic \
                    "Battery at ${percent}%" "Below 30%${remaining:+, $remaining}." ;;
        esac
        last_low="$level"
    fi
    [ "$percent" -ge "$LOW_REARM" ] && last_low=""
fi

# ── charging: hint once above 80% ────────────────────────────
if [ "$charge_state" != "discharging" ] && [ "$percent" -gt "$HIGH_LEVEL" ]; then
    if [ "$last_high" != "$HIGH_LEVEL" ]; then
        notify 7005 low battery-level-80-charging-symbolic \
            "Battery at ${percent}%" "Above 80%${remaining:+, $remaining}. Unplug to save cycles."
        last_high="$HIGH_LEVEL"
    fi
fi
[ "$percent" -lt "$HIGH_REARM" ] && last_high=""

save_state "$last_low" "$last_high"
