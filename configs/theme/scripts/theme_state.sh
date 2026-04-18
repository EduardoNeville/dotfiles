#!/bin/bash
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}"
STATE_FILE="$STATE_DIR/theme"
mkdir -p "$STATE_DIR"

get_theme() {
    cat "$STATE_FILE" 2>/dev/null || echo "dark"
}

set_theme() {
    echo "$2" > "$STATE_FILE"
}

toggle_theme() {
    current=$(get_theme)
    case $current in
        dark) set_theme "light" ;;
        light) set_theme "dark" ;;
    esac
}

case "$1" in
    get) get_theme ;;
    set) set_theme "$@" ;;
    toggle) toggle_theme ;;
    *) echo "Usage: theme {get|set <theme>|toggle}" ;;
esac