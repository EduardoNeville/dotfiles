#!/bin/sh
# battery_guard.sh — hibernate before the internal battery's cutoff kills the box.
#
#   battery_guard.sh                                    # live readings (system timer)
#   battery_guard.sh --selftest                         # assert the decision table
#   BATTERY_GUARD_DRY_RUN=1 battery_guard.sh            # decide, do not hibernate
#   BATTERY_GUARD_TEST_CAPACITY=25 BATTERY_GUARD_DRY_RUN=1 battery_guard.sh
#
# Why this exists: this T480 has two packs and the EC drains BAT0 (internal,
# 01AV420) first. BAT0's health is 78.7% and its internal resistance ~160 mOhm,
# so under a 15-25 W load the terminal voltage hits the EC's floor while the
# fuel gauge still shows 8-13%: the machine loses power instantly, no shutdown,
# no panic, no log — the journal just stops.
#
# UPower cannot cover this: its critical action (PercentageAction=2,
# CriticalPowerAction=HybridSleep) is evaluated on the *combined* DisplayDevice,
# which stays above ~48% while BAT1 is full, so it never fires. Same reason the
# averaged status-bar reading and battery_notify.sh's warnings never fired.
#
# Runs as a *system* unit (root): hibernating from a user unit would need polkit
# authentication, which a timer has no way to provide. STATE_FILE remembers the
# level we hibernated at, so resuming on a still-low pack does not loop; it is
# cleared whenever the machine is on AC.

set -u

BAT_GLOB=${BATTERY_GUARD_BAT_GLOB:-/sys/class/power_supply/BAT*}
AC_PATH=${BATTERY_GUARD_AC:-/sys/class/power_supply/AC/online}
THRESHOLD=${BATTERY_GUARD_THRESHOLD:-25}   # hibernate at/below this BAT0 level
REARM=${BATTERY_GUARD_REARM:-5}            # points to drop before firing again
FLOOR=${BATTERY_GUARD_FLOOR:-15}           # always hibernate at/below this
STATE_FILE=${BATTERY_GUARD_STATE:-/var/lib/battery-guard/last}
DRY_RUN=${BATTERY_GUARD_DRY_RUN:-0}
TEST_CAPACITY=${BATTERY_GUARD_TEST_CAPACITY:-}

log() {
    logger -t battery-guard "$*" 2>/dev/null || true
    [ "$DRY_RUN" = 1 ] && printf 'battery-guard: %s\n' "$*"
    return 0
}

is_num() { case "${1:-}" in ''|*[!0-9]*) return 1 ;; *) return 0 ;; esac; }

# decide <capacity> <last_hibernated_capacity> -> hibernate | hold
decide() {
    is_num "$1" && is_num "$2" || { echo hold; return; }
    [ "$1" -le "$THRESHOLD" ] || { echo hold; return; }
    [ "$1" -le "$FLOOR" ] && { echo hibernate; return; }
    [ "$1" -le $(( $2 - REARM )) ] && { echo hibernate; return; }
    echo hold
}

selftest() {
    rc=0
    check() {
        got="$(decide "$1" "$2")"
        if [ "$got" != "$3" ]; then
            echo "FAIL decide($1,$2)=$got expected $3"
            rc=1
        fi
    }
    check 60 100 hold          # well above the threshold
    check 30 100 hold          # above the threshold
    check 25 100 hibernate     # at the threshold -> fire
    check 26 30 hold           # just below the last hibernate: no loop
    check 24 30 hibernate      # REARM points below the last one -> fire
    check 21 25 hold           # 4 points: not enough
    check 20 25 hibernate      # exactly REARM points
    check 15 15 hibernate      # floor wins over the re-arm rule
    check 14 100 hibernate     # floor
    check "" 100 hold          # unreadable reading never hibernates
    check abc 100 hold
    [ "$rc" = 0 ] && echo "battery_guard: selftest ok (threshold=${THRESHOLD} rearm=${REARM} floor=${FLOOR})"
    return "$rc"
}

[ "${1:-}" = "--selftest" ] && { selftest; exit $?; }

is_num "$THRESHOLD" && is_num "$REARM" && is_num "$FLOOR" || {
    log "bad configuration (threshold='${THRESHOLD}' rearm='${REARM}' floor='${FLOOR}')"
    exit 1
}

# On AC (or charging): re-arm fully.
if [ "$(cat "$AC_PATH" 2>/dev/null)" = "1" ]; then
    rm -f "$STATE_FILE"
    exit 0
fi

capacity="$TEST_CAPACITY"
source_bat=""
if [ -z "$capacity" ]; then
    # Lowest level among the packs that are actually supplying power. The EC
    # drains BAT0 (internal) first, but after a reboot it runs off BAT1 instead —
    # whichever is discharging is the one that will die first.
    for bat in $BAT_GLOB; do
        [ -d "$bat" ] || continue
        [ "$(cat "$bat/status" 2>/dev/null || echo "")" = "Discharging" ] || continue
        c="$(cat "$bat/capacity" 2>/dev/null || echo "")"
        is_num "$c" || continue
        if [ -z "$capacity" ] || [ "$c" -lt "$capacity" ]; then
            capacity="$c"
            source_bat="$(basename "$bat")"
        fi
    done
    [ -n "$capacity" ] || exit 0        # nothing discharging: nothing to guard
fi
is_num "$capacity" || { log "cannot read a discharging battery's capacity"; exit 1; }

last="$(cat "$STATE_FILE" 2>/dev/null || echo "")"
is_num "$last" || last=100

if [ "$(decide "$capacity" "$last")" = "hibernate" ]; then
    log "${source_bat:-battery} at ${capacity}% (last hibernate ${last}%, threshold ${THRESHOLD}%) — hibernating"
    [ "$DRY_RUN" = 1 ] && exit 0
    mkdir -p "$(dirname "$STATE_FILE")"
    printf '%s\n' "$capacity" >"$STATE_FILE"
    exec systemctl hibernate
fi

# Only speak up near the decision point, so the journal stays readable.
[ "$capacity" -le $(( THRESHOLD + 5 )) ] && log "${source_bat:-battery} at ${capacity}% — holding (threshold ${THRESHOLD}%)"
exit 0
