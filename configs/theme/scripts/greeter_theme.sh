#!/bin/bash
# greeter_theme.sh — write slick-greeter's config from the shared theme state.
#
# slick-greeter draws BOTH the lightdm login screen and light-locker's lock
# screen, so this one file decides what the password prompt looks like. It is
# reached through a symlink created once by
# profiles/desktop/scripts/setup_lightdm.sh:
#
#   /etc/lightdm/slick-greeter.conf -> ${XDG_STATE_HOME:-~/.local/state}/slick-greeter.conf
#
# The real file lives in the user's state dir on purpose: propagate_state.sh can
# then retint login AND lock screen on every Ctrl+Shift+Y without needing root.
#
# Usage: greeter_theme.sh [light|dark]   (default: read the state file)
# No-op-safe on machines without lightdm: it just writes the state file.

set -u

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}"
STATE_FILE="$STATE_DIR/theme"
CONF="$STATE_DIR/slick-greeter.conf"
LOG_FILE="$STATE_DIR/theme-propagate.log"
ASSETS="${DOTFILES_DIR:-$HOME/dotfiles}/assets"

_log() {
    printf '%s [greeter] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG_FILE"
}

THEME="${1:-}"
if [ -z "$THEME" ]; then
    THEME=$(cat "$STATE_FILE" 2>/dev/null || echo dark)
fi

case "$THEME" in
    light)
        BACKGROUND="$ASSETS/plain_light.png" # flat #FAFAFA, matches the light palette
        THEME_NAME="Adwaita"
        BG_COLOR="#FAFAFA"
        ;;
    *)
        THEME="dark"
        BACKGROUND="$ASSETS/hands_of_god.png"
        THEME_NAME="Adwaita-dark"
        BG_COLOR="#011627" # Night Owl surface, matches dwm's dark bar (config.h)
        ;;
esac

mkdir -p "$STATE_DIR"

# Missing artwork must not mean a black screen at the login prompt.
if [ ! -r "$BACKGROUND" ]; then
    _log "background '$BACKGROUND' unreadable; using solid $BG_COLOR"
    BACKGROUND=""
fi

{
    printf '[Greeter]\n'
    [ -n "$BACKGROUND" ] && printf 'background=%s\n' "$BACKGROUND"
    printf 'background-color=%s\n' "$BG_COLOR"
    printf 'draw-user-backgrounds=false\n'
    printf 'show-clock=true\n'
    printf 'show-power=true\n'
    printf 'logo=%s\n' "$ASSETS/hands_of_god.png"
    printf 'theme-name=%s\n' "$THEME_NAME"
    printf 'icon-theme-name=Adwaita\n'
} >"$CONF.tmp" 2>/dev/null && mv "$CONF.tmp" "$CONF" 2>/dev/null

if [ -r "$CONF" ]; then
    _log "wrote $CONF (theme=$THEME, theme-name=$THEME_NAME)"
else
    _log "FAILED to write $CONF"
    exit 1
fi
