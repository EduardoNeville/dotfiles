#!/bin/bash
# Minimal theme state reader/writer shared by Wezterm, tmux and scripts.
#
#   theme get     — print the current theme (default: dark)
#   theme set X   — write X to the state file
#   theme toggle  — flip dark <-> light
#
# set/toggle append a timestamped line to ~/.local/state/theme-propagate.log
# so state changes are traceable even when the caller shows no output.

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}"
STATE_FILE="$STATE_DIR/theme"
LOG_FILE="$STATE_DIR/theme-propagate.log"
mkdir -p "$STATE_DIR"

_log() {
    printf '%s [theme-state] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG_FILE"
}

get_theme() {
    cat "$STATE_FILE" 2>/dev/null || echo "dark"
}

set_theme() {
    local value="${1:-}"
    if [ -z "$value" ]; then
        echo "usage: theme set <dark|light>" >&2
        return 1
    fi
    echo "$value" > "$STATE_FILE"
    _log "state set to '$value'"
}

toggle_theme() {
    local current
    current=$(get_theme)
    case $current in
        dark) set_theme "light" ;;
        light) set_theme "dark" ;;
        *) _log "toggle: unknown current theme '$current'; defaulting to 'light'"; set_theme "light" ;;
    esac
}

case "$1" in
    get) get_theme ;;
    set) set_theme "$2" ;;
    toggle) toggle_theme ;;
    *) echo "Usage: theme {get|set <theme>|toggle}" >&2 ;;
esac
