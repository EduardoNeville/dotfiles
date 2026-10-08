#!/bin/bash
# Apply the desktop wallpaper for the current theme.
#
#   wallpaper.sh    — read ~/.local/state/theme, set the matching asset with feh
#
# Called by dwm-session.sh (session start) and propagate_state.sh (every
# toggle), so the theme -> wallpaper mapping lives in exactly one place and the
# desktop does not stay dark under a light bar.
#
# Prints one line: "applied <file>" or "skipped: <reason>". Exits 0 either way —
# a headless host (deep-blue) has no feh and nothing to wallpaper.

set -u

STATE_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/theme"
DOTFILES="${DOTFILES_DIR:-$HOME/dotfiles}"
THEME="$(cat "$STATE_FILE" 2>/dev/null || echo dark)"

if [ "$THEME" = "light" ]; then
    WALLPAPER="$DOTFILES/assets/plain_light.png"
else
    WALLPAPER="$DOTFILES/assets/hands_of_god.png"
fi

[ -f "$WALLPAPER" ] || { echo "skipped: missing $WALLPAPER"; exit 0; }
command -v feh >/dev/null 2>&1 || { echo "skipped: feh not installed"; exit 0; }

feh --bg-fill "$WALLPAPER" && echo "applied $(basename "$WALLPAPER")"
