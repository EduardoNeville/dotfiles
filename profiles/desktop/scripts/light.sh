#!/bin/sh
# light.sh — the single owner of panel brightness.
#
# One scale, 0..130%, so the brightness keys never run out of room:
#
#   0..100   hardware backlight through brightnessctl (real nits)
#   101..130 hardware at 100% + a gamma-LUT curve (lut.py), which lifts
#            midtones ~23% at 130 without touching white. It cannot add
#            light — the panel is already at full duty — but it stops dark
#            content from reading as black.
#
# Why a single owner: three things write this state (boot, keys, session
# start) and two of them used to disagree. systemd-backlight restores whatever
# was saved at the last shutdown (36% on this machine), and picom installs an
# identity LUT when it starts, which silently discarded any curve. So the
# session calls `light.sh restore` after picom is up, and every key press
# writes through here.
#
# State lives in $XDG_STATE_HOME/brightness and .../vib so it survives the
# reboot that systemd-backlight would otherwise answer with a stale value.
#
#   light.sh get
#   light.sh default              the level a fresh install starts at
#   light.sh set <pct>            absolute, clamped 0..$LIGHT_CEILING
#   light.sh up [step] | down [step]
#   light.sh restore              re-apply saved backlight + curve + vibrance
#   light.sh reset                100% hardware, identity LUT, identity CTM
#   light.sh vib <0-40> | viboff  extra colour saturation (CTM), 0 = off
#   light.sh diag                 what the hardware and the server hold
#
# Called from dwm config.h (XF86MonBrightnessUp/Down) and dwm-session.sh.

set -u

SCRIPTS="${DOTFILES_DIR:-$HOME/dotfiles}/profiles/desktop/scripts"
LUT="$SCRIPTS/lut.py"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}"
STATE="$STATE_DIR/brightness"
VIB_STATE="$STATE_DIR/vib"
CEILING="${LIGHT_CEILING:-130}"
STEP_DEFAULT="${LIGHT_STEP:-5}"
# Where a fresh install starts. Above 100% on purpose: the panel's 100% duty is
# the hardware ceiling, and the whole point of the curve is that a new machine
# looks like a tuned one (midtone +15% at 120) without anyone pressing a key.
# This is a *default*, not a lock — the first `light.sh set/up/down` writes the
# user's own state and this value stops mattering.
DEFAULT_LEVEL="${LIGHT_DEFAULT:-120}"

notify() {
    # Same stack tag as the other OSD helpers: one bar that updates in place.
    command -v dunstify >/dev/null 2>&1 || return 0
    dunstify -a backlight -u low -t 900 \
        -h string:x-dunst-stack-tag:brightness \
        -h "int:value:$1" "Brightness" "$2" 2>/dev/null || true
}

read_saved() {
    if [ -r "$STATE" ]; then
        saved=$(tr -dc '0-9' <"$STATE" 2>/dev/null)
        [ -n "$saved" ] && printf '%s' "$saved" && return 0
    fi
    printf '%s' "$DEFAULT_LEVEL"
}

read_vib() {
    if [ -r "$VIB_STATE" ]; then
        v=$(tr -dc '0-9' <"$VIB_STATE" 2>/dev/null)
        [ -n "$v" ] && printf '%s' "$v" && return 0
    fi
    printf '0'
}

write_state() {
    mkdir -p "$STATE_DIR" 2>/dev/null || true
    printf '%s\n' "$1" >"$STATE" 2>/dev/null || true
}

clamp() {
    [ "$1" -lt 0 ] && echo 0 && return
    [ "$1" -gt "$CEILING" ] && echo "$CEILING" && return
    echo "$1"
}

apply_lut() {
    [ -n "${DISPLAY:-}" ] && [ -x "$LUT" ] || return 0
    # pct<=100 means identity: the backlight does the work, no curve stacked
    # on top (a stale curve is what makes 40% look washed out).
    "$LUT" lum "$1" >/dev/null 2>&1 || true
}

apply_pct() {
    pct=$(clamp "$1")
    if ! command -v brightnessctl >/dev/null 2>&1; then
        printf 'light.sh: brightnessctl not installed\n' >&2
        return 1
    fi
    if [ "$pct" -le 100 ]; then
        brightnessctl -q set "${pct}%" || return 1
        apply_lut 100
        label="${pct}%"
    else
        # Hardware first: never trade away real nits for a curve.
        brightnessctl -q set 100% || return 1
        apply_lut "$pct"
        label="${pct}% (curve)"
    fi
    write_state "$pct"
    notify "$pct" "$label"
}

apply_vib() {
    vib=$(clamp "$1" 2>/dev/null || echo 0)
    [ "$vib" -gt 40 ] && vib=40
    if [ -n "${DISPLAY:-}" ] && [ -x "$LUT" ]; then
        "$LUT" vib "$vib" >/dev/null 2>&1 || true
    fi
    mkdir -p "$STATE_DIR" 2>/dev/null || true
    printf '%s\n' "$vib" >"$VIB_STATE" 2>/dev/null || true
    notify "$(read_saved)" "saturation ${vib}%"
}

case "${1:-get}" in
get)
    printf '%s\n' "$(read_saved)"
    ;;
default)
    printf '%s\n' "$DEFAULT_LEVEL"
    ;;
set)
    apply_pct "${2:-$(read_saved)}"
    ;;
up)
    apply_pct "$(($(read_saved) + ${2:-$STEP_DEFAULT}))"
    ;;
down)
    apply_pct "$(($(read_saved) - ${2:-$STEP_DEFAULT}))"
    ;;
restore)
    apply_pct "$(read_saved)"
    [ "$(read_vib)" -gt 0 ] && apply_vib "$(read_vib)"
    ;;
reset)
    printf '100\n' >"$STATE" 2>/dev/null || true
    apply_pct 100
    [ -n "${DISPLAY:-}" ] && [ -x "$LUT" ] && "$LUT" vib 0 >/dev/null 2>&1 || true
    ;;
vib)
    apply_vib "${2:-0}"
    ;;
viboff)
    apply_vib 0
    ;;
diag)
    printf 'saved=%s%%  ceiling=%s%%  step=%s%%  vib=%s%%\n' \
        "$(read_saved)" "$CEILING" "$STEP_DEFAULT" "$(read_vib)"
    if command -v brightnessctl >/dev/null 2>&1; then
        printf 'backlight: %s/%s\n' "$(brightnessctl g)" "$(brightnessctl m)"
    fi
    [ -n "${DISPLAY:-}" ] && [ -x "$LUT" ] && "$LUT" show
    ;;
*)
    printf 'usage: light.sh {get|default|set N|up [step]|down [step]|restore|reset|vib N|viboff|diag}\n' >&2
    exit 2
    ;;
esac
