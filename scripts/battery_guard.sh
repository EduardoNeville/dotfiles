#!/bin/sh
# battery_guard.sh — hand the load to the healthy pack at 10%, hibernate if
# the firmware will not yield.
#
#   battery_guard.sh                                    # live readings (system timer)
#   battery_guard.sh --selftest                         # assert the decision table
#   BATTERY_GUARD_DRY_RUN=1 battery_guard.sh            # decide, do not write/sleep
#
# Why this exists: this T480 has two packs (BAT0 internal, BAT1 external) and
# the EC — not Linux — chooses which one discharges. The ACPI/thinkpad_acpi
# interface exposes `charge_behaviour` with `force-discharge`, but no "make
# BAT0 the source" knob. On the T480 the EC normally drains the external pack
# down to its own cutoff and only then reaches for BAT0. A worn pack's fuel
# gauge can still report 10-20% while its cells are at the design minimum
# voltage, so the machine loses power before that handover happens.
#
# The guard therefore:
#   1. On AC: undo any force-discharge we requested, clear state, exit.
#   2. Finds the pack that is actually supplying power (lowest Discharging
#      pack; lowest present pack as a fallback when status files are broken).
#   3. At SWITCH_AT (10%) and with a peer above PEER_MIN (15%), asks the EC to
#      move the load: write `force-discharge` to the peer's charge_behaviour,
#      wait GRACE seconds, and verify the source stopped discharging. If it
#      worked, the peer stays forced until AC is attached. If the firmware
#      ignored it, put the peer back to `auto` and fall through.
#   4. If no handover happened, hibernate at FLOOR (10%) instead of letting
#      the EC's cutoff kill the session. The next power-on makes the EC
#      re-evaluate both packs. STATE_FILE remembers the level we hibernated at
#      so resuming on a still-low pack does not loop until it drops REARM more
#      points; it is cleared on AC and after a successful handover.
#
# `force-discharge` is best-effort, not a guarantee. On some ThinkPads it only
# works while AC is attached (TLP documents it as a calibration mode), on
# others it selects the pack on battery too. We verify, never assume; the
# hibernate is the safety net either way.
#
# Runs as a *system* unit (root): writing charge_behaviour and hibernating
# from a user unit would need polkit authentication, which a timer has no way
# to provide. The unit/script must be root-owned copies on the root
# filesystem: /home is a separate mount, so a unit symlinked into /home is not
# resolvable when systemd builds its unit table at boot. configure_system.sh
# installs the copies; scripts/install_battery_guard.sh repairs an existing
# machine.

set -u

BAT_GLOB=${BATTERY_GUARD_BAT_GLOB:-/sys/class/power_supply/BAT*}
AC_GLOB=${BATTERY_GUARD_AC_GLOB:-/sys/class/power_supply/A*/online /sys/class/power_supply/ucsi-source-psy-*/online}
SWITCH_AT=${BATTERY_GUARD_SWITCH_AT:-10}   # request handover at/below this %
PEER_MIN=${BATTERY_GUARD_PEER_MIN:-15}     # peer must have at least this %
FLOOR=${BATTERY_GUARD_FLOOR:-10}           # hibernate at/below this if no handover
REARM=${BATTERY_GUARD_REARM:-1}            # points to drop before hibernate again
GRACE=${BATTERY_GUARD_GRACE:-10}           # seconds to wait for the EC to switch
IDLE_UW=${BATTERY_GUARD_IDLE_UW:-500000}   # 0.5 W: treat the old source as idle
HANDOVER=${BATTERY_GUARD_HANDOVER:-force}  # force | off
STATE_DIR=${BATTERY_GUARD_STATE_DIR:-/var/lib/battery-guard}
STATE_FILE=${BATTERY_GUARD_STATE:-${STATE_DIR}/last}
FORCED_FILE=${STATE_DIR}/forced
DRY_RUN=${BATTERY_GUARD_DRY_RUN:-0}
NO_HIBERNATE=${BATTERY_GUARD_NO_HIBERNATE:-0}   # test switch: never call systemctl
TEST_CAPACITY=${BATTERY_GUARD_TEST_CAPACITY:-}

log() {
    logger -t battery-guard "$*" 2>/dev/null || true
    [ "$DRY_RUN" = 1 ] && printf 'battery-guard: %s\n' "$*"
    return 0
}

is_num() { case "${1:-}" in ''|*[!0-9]*) return 1 ;; *) return 0 ;; esac; }

read_int() { # read_int <file> -> value, empty when unreadable
    [ -f "$1" ] || return 0
    cat "$1" 2>/dev/null || true
}

# peer_ok <capacity> — is the other pack worth switching to?
peer_ok() {
    is_num "${1:-}" || return 1
    [ "$1" -ge "$PEER_MIN" ] && [ "$1" -gt "$SWITCH_AT" ]
}

# decide_hibernate <capacity> <last_hibernated_capacity> -> 0 hibernate, 1 hold
decide_hibernate() {
    is_num "$1" && is_num "$2" || return 1
    [ "$1" -le "$FLOOR" ] || return 1
    [ "$1" -le $(( $2 - REARM )) ] || return 1
    return 0
}

selftest() {
    rc=0
    check_hib() {
        if decide_hibernate "$1" "$2"; then got=yes; else got=no; fi
        if [ "$got" != "$3" ]; then
            echo "FAIL decide_hibernate($1,$2)=$got expected $3"
            rc=1
        fi
    }
    check_peer() {
        if peer_ok "$1"; then got=yes; else got=no; fi
        if [ "$got" != "$2" ]; then
            echo "FAIL peer_ok($1)=$got expected $2"
            rc=1
        fi
    }

    # Above/at the floor: first hit fires, a resumed run does not loop until
    # the pack has dropped REARM more points.
    check_hib $((FLOOR + 1)) 100 no
    check_hib "$FLOOR" 100 yes
    check_hib "$FLOOR" "$FLOOR" no
    check_hib $((FLOOR - 1)) "$FLOOR" yes
    check_hib $((FLOOR - REARM)) "$FLOOR" yes
    check_hib "" 100 no
    check_hib abc 100 no

    # Peer must be safely above the switch point (not a 1% "upgrade").
    check_peer "$PEER_MIN" yes
    check_peer $((PEER_MIN - 1)) no
    check_peer "$SWITCH_AT" no
    check_peer "" no
    check_peer abc no

    [ "$rc" = 0 ] && echo "battery_guard: selftest ok (switch=${SWITCH_AT}% peer>=${PEER_MIN}% floor=${FLOOR}% rearm=${REARM})"
    return "$rc"
}

[ "${1:-}" = "--selftest" ] && { selftest; exit $?; }

if ! { is_num "$SWITCH_AT" && is_num "$PEER_MIN" && is_num "$FLOOR" &&
    is_num "$REARM" && is_num "$GRACE" && is_num "$IDLE_UW"; }; then
    log "bad configuration (switch='${SWITCH_AT}' peer='${PEER_MIN}' floor='${FLOOR}' rearm='${REARM}' grace='${GRACE}')"
    exit 1
fi

# ── AC: release any forced pack and re-arm the guard ─────────────────────────
read_ac() {
    # AC/online is the barrel adapter; the T480 also charges over USB-C, where
    # the supply is ucsi-source-psy-*/online. Any online source counts as AC.
    for acf in $AC_GLOB; do
        [ -f "$acf" ] || continue
        [ "$(read_int "$acf")" = "1" ] && { echo 1; return 0; }
    done
    echo 0
}

ac_online="$(read_ac)"

cleanup_forced() {
    [ -f "$FORCED_FILE" ] || return 0
    forced_path="$(read_int "$FORCED_FILE")"
    case "$forced_path" in
    /*) ;;
    BAT[0-9]*) forced_path="/sys/class/power_supply/${forced_path}" ;;
    *) rm -f "$FORCED_FILE"; return 0 ;;
    esac
    forced="$(basename "$forced_path")"
    case "$forced" in BAT[0-9]*) ;; *) rm -f "$FORCED_FILE"; return 0 ;; esac
    bf="${forced_path}/charge_behaviour"
    if [ -f "$bf" ]; then
        cur="$(read_int "$bf")"
        case "$cur" in
        *"[force-discharge]"* | force-discharge)
            if [ "$DRY_RUN" = 1 ]; then
                log "would reset ${forced} charge_behaviour to auto"
            elif ! printf 'auto\n' >"$bf" 2>/dev/null; then
                log "could not reset ${forced} charge_behaviour to auto"
                return 1
            else
                log "reset ${forced} charge_behaviour to auto"
            fi
            ;;
        esac
    fi
    rm -f "$FORCED_FILE"
    return 0
}

if [ "$ac_online" = "1" ]; then
    if cleanup_forced; then
        rm -f "$STATE_FILE" "$FORCED_FILE"
    else
        # Keep FORCED_FILE so the next AC run retries the reset.
        rm -f "$STATE_FILE"
        exit 1
    fi
    exit 0
fi

# ── read the packs ───────────────────────────────────────────────────────────
# Two passes: find the pack that is actually supplying the machine, then the
# best candidate to take over. We deliberately do not use an aggregate:
# BAT0:99%|BAT1:10% averages to 54% and hides the pack about to die.
source_bat="" source_cap="" source_path="" low_bat="" low_cap="" low_path=""
for bat in $BAT_GLOB; do
    [ -d "$bat" ] || continue
    present="$(read_int "$bat/present")"
    [ -z "$present" ] || [ "$present" = "1" ] || continue
    c="$(read_int "$bat/capacity")"
    is_num "$c" || continue
    bn="$(basename "$bat")"
    st="$(read_int "$bat/status")"

    if [ -z "$low_cap" ] || [ "$c" -lt "$low_cap" ]; then
        low_cap="$c" low_bat="$bn" low_path="$bat"
    fi
    if [ "$st" = "Discharging" ] &&
        { [ -z "$source_cap" ] || [ "$c" -lt "$source_cap" ]; }; then
        source_cap="$c" source_bat="$bn" source_path="$bat"
    fi
done

# No pack says Discharging (flaky EC / status latched): guard the lowest pack
# anyway when AC is offline, so a broken status file cannot silence the guard.
if [ -z "$source_bat" ] && [ -n "$low_bat" ]; then
    source_bat="$low_bat" source_cap="$low_cap" source_path="$low_path"
    log "no pack reports Discharging; falling back to lowest pack ${source_bat} at ${source_cap}%"
fi
[ -n "$source_bat" ] || exit 0        # on AC / no readable battery: nothing to guard

source_cap="${TEST_CAPACITY:-$source_cap}"
is_num "$source_cap" || { log "cannot read ${source_bat} capacity"; exit 1; }

# Best peer: highest-capacity present pack other than the source.
peer_bat="" peer_cap="" peer_path=""
for bat in $BAT_GLOB; do
    [ -d "$bat" ] || continue
    present="$(read_int "$bat/present")"
    [ -z "$present" ] || [ "$present" = "1" ] || continue
    bn="$(basename "$bat")"
    [ "$bn" = "$source_bat" ] && continue
    c="$(read_int "$bat/capacity")"
    is_num "$c" || continue
    if [ -z "$peer_cap" ] || [ "$c" -gt "$peer_cap" ]; then
        peer_cap="$c" peer_bat="$bn" peer_path="$bat"
    fi
done

last="$(read_int "$STATE_FILE")"
is_num "$last" || last=100

# ── handover / safety decision ───────────────────────────────────────────────
if [ "$source_cap" -le "$SWITCH_AT" ]; then
    if [ "$HANDOVER" = "force" ] && [ -n "$peer_bat" ] && peer_ok "$peer_cap"; then
        behavior="${peer_path}/charge_behaviour"
        cur="$(read_int "$behavior")"
        case "$cur" in
        *force-discharge*) supported=1 ;;
        *) supported=0 ;;
        esac

        if [ "$supported" = 1 ]; then
            # Record the pack before writing: if we crash between the write and
            # the AC cleanup, the next AC run can still put it back to auto.
            if [ "$DRY_RUN" != 1 ]; then
                mkdir -p "$STATE_DIR" 2>/dev/null || true
                printf '%s\n' "$peer_path" >"$FORCED_FILE" 2>/dev/null || true
            fi
            if [ "$DRY_RUN" = 1 ]; then
                log "would request handover ${source_bat}(${source_cap}%) -> ${peer_bat}(${peer_cap}%) via force-discharge"
                exit 0
            fi
            if printf 'force-discharge\n' >"$behavior" 2>/dev/null; then
                log "requested handover ${source_bat}(${source_cap}%) -> ${peer_bat}(${peer_cap}%); waiting ${GRACE}s"
                sleep "$GRACE"
                # If AC appeared during the grace window, do not leave a forced
                # pack behind: restore it and let the next run see AC online.
                if [ "$(read_ac)" = "1" ]; then
                    log "AC connected during handover; restoring ${peer_bat} to auto"
                    cur="$(read_int "$behavior")"
                    case "$cur" in
                    *"[force-discharge]"* | force-discharge)
                        if printf 'auto\n' >"$behavior" 2>/dev/null; then
                            rm -f "$FORCED_FILE"
                        else
                            log "could not restore ${peer_bat} to auto; will retry on AC"
                        fi
                        ;;
                    *) rm -f "$FORCED_FILE" ;;
                    esac
                    rm -f "$STATE_FILE"
                    exit 0
                fi
                new_source_status="$(read_int "${source_path}/status")"
                new_source_power="$(read_int "${source_path}/power_now")"
                new_peer_status="$(read_int "${peer_path}/status")"
                new_peer_power="$(read_int "${peer_path}/power_now")"
                if { [ "$new_source_status" != "Discharging" ] &&
                    [ "$new_peer_status" = "Discharging" ]; } ||
                    { is_num "$new_source_power" && [ "$new_source_power" -le "$IDLE_UW" ] &&
                        is_num "$new_peer_power" && [ "$new_peer_power" -gt "$IDLE_UW" ]; }; then
                    rm -f "$STATE_FILE"
                    log "handover succeeded: ${source_bat}=${new_source_status} ${new_source_power}uW, ${peer_bat}=${new_peer_status} ${new_peer_power}uW"
                    exit 0
                fi
                log "handover not accepted (source ${new_source_status} ${new_source_power}uW, peer ${new_peer_status} ${new_peer_power}uW); restoring ${peer_bat} to auto"
                cur="$(read_int "$behavior")"
                case "$cur" in
                *"[force-discharge]"* | force-discharge)
                    if printf 'auto\n' >"$behavior" 2>/dev/null; then
                        rm -f "$FORCED_FILE"
                    else
                        log "could not restore ${peer_bat} to auto; will retry on AC"
                    fi
                    ;;
                *) rm -f "$FORCED_FILE" ;;
                esac
            else
                log "could not write force-discharge to ${peer_bat}; keeping state for AC cleanup"
            fi
        else
            log "${peer_bat} does not advertise force-discharge; not attempting a live handover"
        fi
    else
        [ -z "$peer_bat" ] && log "no other battery to hand over to"
        [ -n "$peer_bat" ] && [ "$HANDOVER" = "force" ] &&
            log "peer ${peer_bat} at ${peer_cap}% is below the ${PEER_MIN}% handover minimum"
        [ "$HANDOVER" != "force" ] && log "live handover disabled (BATTERY_GUARD_HANDOVER=${HANDOVER})"
    fi

    if decide_hibernate "$source_cap" "$last"; then
        log "${source_bat} at ${source_cap}% (floor ${FLOOR}%, last hibernate ${last}%) — hibernating"
        if [ "$DRY_RUN" = 1 ]; then
            log "would hibernate now"
            exit 0
        fi
        mkdir -p "$STATE_DIR" 2>/dev/null || true
        printf '%s\n' "$source_cap" >"$STATE_FILE" 2>/dev/null || true
        if [ "$NO_HIBERNATE" = 1 ]; then
            log "test mode: hibernate suppressed"
            exit 0
        fi
        if ! systemctl hibernate; then
            # Do not leave a state entry that would suppress the next retry
            # until the level drops another REARM points.
            rm -f "$STATE_FILE"
            log "hibernate failed; guard will retry on the next timer run"
            exit 1
        fi
        exit 0
    fi
fi

# Only speak up near the decision point, so the journal stays readable.
if [ "$source_cap" -le $((SWITCH_AT + 5)) ]; then
    log "${source_bat} at ${source_cap}% — holding (switch at ${SWITCH_AT}%, floor ${FLOOR}%)"
fi
exit 0
