#!/bin/sh
# battery_notify.sh — battery warnings, every minute, on the pack that matters.
#
#   battery_notify.sh                                   # real readings (timer)
#   battery_notify.sh --selftest                        # assert the decision table
#   battery_notify.sh --dry-run                         # print, do not notify-send
#   battery_notify.sh --dry-run --percent 25 --state discharging --name BAT0
#
# Design rules (measured on this T480):
#   - The pack that is *Discharging* is the one that will kill the machine (the
#     EC drains BAT0 first, but after a reboot it runs off BAT1 instead — see
#     scripts/battery_guard.sh). Warn on min(capacity) of the DISCHARGING
#     packs. Using BAT0's status alone or an aggregate over every pack is how
#     the warnings used to silently never fire.
#   - No discharging pack but a Charging one above 80% -> the "unplug to save
#     cycles" hint. That is computed on the charging packs, never on the
#     aggregate, or a stuck 4% sibling would keep it suppressed forever.
#   - Reminders REPEAT: while the condition holds, each run re-sends (same
#     replace id, so dunst refreshes one popup instead of stacking).
#
# Runs as a systemd *user* service, so it has no session environment: the
# session bus address is derived from XDG_RUNTIME_DIR when it is missing
# (notify-send is a pure D-Bus client; dunst owns the display; with the repo
# dunstrc it follows the focused window, i.e. the pane you are on).

set -u

LOW_LEVELS="30 20 10"   # descending tiers; the tightest one the level is under wins
HIGH_LEVEL=80

DRY_RUN=0
percent=""      # test override
charge_state="" # test override
name=""         # test override (which battery is reported)

while [ $# -gt 0 ]; do
    case "$1" in
        --percent) percent="${2:-}"; shift 2 || shift ;;
        --percent=*) percent="${1#*=}"; shift ;;
        --state)  charge_state="${2:-}"; shift 2 || shift ;;
        --state=*) charge_state="${1#*=}"; shift ;;
        --name)   name="${2:-}"; shift 2 || shift ;;
        --name=*) name="${1#*=}"; shift ;;
        --dry-run) DRY_RUN=1; shift ;;
        --selftest) SELFTEST=1; shift ;;
        *) echo "usage: $0 [--selftest] [--dry-run] [--percent N] [--state charging|discharging|full] [--name BAT1]" >&2; exit 2 ;;
    esac
done

# ── decision core (pure, selftestable) ────────────────────────────────────────
# pick <lowest-tier> loop; returns tightest tier crossed, empty if none.
pick_tier() {
    level=""
    for c in $LOW_LEVELS; do
        [ "$1" -lt "$c" ] && level="$c"
    done
    printf "%s" "$level"
}

decide() {
    # decide <status> <capacity> -> "low <tier>" | "high" | ""
    # status compare is case-insensitive: sysfs says "Discharging", callers (and
    # the usage examples) hand us "discharging".
    is_num() { case "${1:-}" in ''|*[!0-9]*) return 1 ;; *) return 0 ;; esac; }
    is_num "$2" || return 0
    st="$(printf %s "${1:-}" | tr 'A-Z' 'a-z')"
    if [ "$st" = "discharging" ]; then
        t="$(pick_tier "$2")"
        [ -n "$t" ] && echo "low $t"
    elif [ "$st" = "charging" ] && [ "$2" -gt "$HIGH_LEVEL" ]; then
        echo "high"
    fi
}

if [ "${SELFTEST:-0}" = 1 ]; then
    rc=0
    check() { got="$(decide "$1" "$2")"; [ "${got:-}" = "$3" ] || { echo "FAIL decide($1,$2)=$got expected ${3:-(empty)}"; rc=1; }; }
    # low side: tier = tightest threshold crossed; at the exact number, not crossed
    check Discharging 30 ""       # 30 is not below 30
    check Discharging 29 "low 30"
    check Discharging 20 "low 30" # 20 is below 30, not below 20
    check Discharging 19 "low 20"
    check Discharging 10 "low 20"
    check Discharging 9 "low 10"
    check Discharging 3 "low 10"
    check Discharging 55 ""
    check Discharging 100 ""
    # high side: charging above 80 only (a stuck low sibling never suppresses it here)
    check Charging 80 ""
    check Charging 81 "high"
    check Charging 4 ""
    # everything else: silence (on AC idle, full, unknown, garbage readings)
    check "Not charging" 4 ""
    check Full 100 ""
    check Unknown 50 ""
    check "" 100 ""
    check Discharging abc ""
    [ "$rc" = 0 ] && echo "battery_notify: selftest ok"
    exit "$rc"
fi

# ── read the batteries unless overridden ─────────────────────────────────────
# Walk every pack, remember its (name status capacity). The *predicate* packs:
#   discharging -> min capacity among them decides low warnings
#   charging    -> max capacity among them decides the >80% hint
if [ -z "$percent" ]; then
    BAT_GLOB=${BATTERY_NOTIFY_BAT_GLOB:-/sys/class/power_supply/BAT*}
    dis_cap="" dis_name=""
    chg_cap="" chg_name=""
    has_status=""
    for bat in $BAT_GLOB; do
        [ -d "$bat" ] || continue
        st="$(cat "$bat/status" 2>/dev/null || echo "")"
        c="$(cat "$bat/capacity" 2>/dev/null || echo "")"
        case "$c" in ''|*[!0-9]*) continue ;; esac
        bn="$(basename "$bat")"
        case "$st" in
            Discharging)
                [ -n "$dis_cap" ] && [ "$c" -ge "$dis_cap" ] || { dis_cap="$c"; dis_name="$bn"; }
                ;;
            Charging)
                [ -n "$chg_cap" ] && [ "$c" -le "$chg_cap" ] || { chg_cap="$c"; chg_name="$bn"; }
                ;;
        esac
    done

    # aggregate: low side wins over the charging hint
    if [ -n "$dis_cap" ]; then
        percent="$dis_cap"; charge_state="Discharging"; name="$dis_name"
    elif [ -n "$chg_cap" ]; then
        percent="$chg_cap"; charge_state="Charging"; name="$chg_name"
    else
        # Status reports missing / all idle (flaky EC): fall back to the lowest
        # pack as "discharging" when AC reports offline, so a broken status
        # file can never silence the warnings the guard pair relies on.
        ac=""
        for acf in ${BATTERY_NOTIFY_AC_GLOB:-/sys/class/power_supply/A*/online}; do
            [ -f "$acf" ] || continue
            ac="$(cat "$acf" 2>/dev/null || echo 0)"
            break
        done
        if [ "${ac:-1}" = 1 ]; then
            echo "on AC, nothing charging; no notification claimed"; exit 0
        fi
        for bat in $BAT_GLOB; do
            [ -d "$bat" ] || continue
            c="$(cat "$bat/capacity" 2>/dev/null || echo "")"
            case "$c" in ''|*[!0-9]*) continue ;; esac
            [ -n "${dis_cap:-}" ] && [ "$c" -ge "${dis_cap:-}" ] || { dis_cap="$c"; dis_name="$(basename "$bat")"; }
        done
        [ -n "${dis_cap:-}" ] || { echo "no readable battery; no notification claimed"; exit 0; }
        percent="$dis_cap"; charge_state="Discharging"; name="$dis_name"
    fi
fi

case "$percent" in ''|*[!0-9]*) echo "cannot determine battery percentage" >&2; exit 1 ;; esac
[ -n "$name" ] || name="battery"

# notify <replace-id> <urgency> <icon> <summary> [body]
notify() {
    _id="$1" _urgency="$2" _icon="$3" _summary="$4" _extra="${5:-}"
    if [ "$DRY_RUN" = 1 ]; then
        echo "would notify [$_urgency] $_summary — ${_extra:-$name at ${percent}%.}"
        return 0
    fi
    command -v notify-send >/dev/null 2>&1 || { echo "notify-send missing" >&2; return 1; }
    : "${DBUS_SESSION_BUS_ADDRESS:=unix:path=${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/bus}"
    export DBUS_SESSION_BUS_ADDRESS
    notify-send -r "$_id" -u "$_urgency" -i "$_icon" -h int:value:"$percent" \
        "$_summary" "${_extra:-$name at ${percent}%.}"
}

verdict="$(decide "${charge_state:-}" "$percent")"
case "$verdict" in
    "low 10")
        notify 7004 critical battery-caution-symbolic \
            "Battery critical: $name ${percent}%" "Plug in now — about to cut off." ;;
    "low 20")
        notify 7003 normal battery-level-20-symbolic \
            "Battery low: $name ${percent}%" "Under 20% — plug in soon." ;;
    "low 30")
        notify 7002 normal battery-level-30-symbolic \
            "Battery at $name ${percent}%" "Below 30%." ;;
    high)
        notify 7005 low battery-level-80-charging-symbolic \
            "Battery at $name ${percent}%" "Above 80% — unplug to save cycles." ;;
    "")
        # e.g. plugged in, charging below 80: audibly nothing to claim
        [ "$DRY_RUN" = 1 ] && echo "no threshold crossed ($name $charge_state at ${percent}%)" >&2
        exit 0 ;;
esac
