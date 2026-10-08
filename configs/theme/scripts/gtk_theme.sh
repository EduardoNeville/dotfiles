#!/bin/bash
# gtk_theme.sh — tell the desktop which appearance the theme state asks for.
#
#   gtk_theme.sh    — read ~/.local/state/theme, write the GSettings appearance
#
# This machine has no desktop environment and no xdg-desktop-portal, so the
# GSettings keys below are the *only* appearance signal GTK apps and Firefox get:
#
#   - Firefox reads org.gnome.desktop.interface (gtk-theme, color-scheme) through
#     GIO when no portal is available. Its profile keeps the System theme
#     (default-theme@mozilla.org) and leaves
#     layout.css.prefers-color-scheme.content-override unset (= follow system),
#     so both the browser chrome and prefers-color-scheme on web pages follow
#     this.
#   - GTK apps (light-locker, blueman, …) follow gtk-theme.
#
#   dark  -> color-scheme prefer-dark,  gtk-theme Adwaita-dark
#   light -> color-scheme prefer-light, gtk-theme Adwaita
#
# Called by propagate_state.sh on every Ctrl+Shift+Y. Exits 1 if dconf cannot be
# written (the usual cause is a missing D-Bus session bus, e.g. from a bare tty).

set -u

STATE_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/theme"
THEME="$(cat "$STATE_FILE" 2>/dev/null || echo dark)"

command -v gsettings >/dev/null 2>&1 || { echo "skipped: gsettings not installed"; exit 0; }

if [ "$THEME" = "light" ]; then
    scheme=prefer-light
    gtk=Adwaita
else
    scheme=prefer-dark
    gtk=Adwaita-dark
fi

if ! gsettings set org.gnome.desktop.interface color-scheme "$scheme" 2>/dev/null; then
    echo "FAILED: cannot write color-scheme (no D-Bus session bus?)"
    exit 1
fi
if ! gsettings set org.gnome.desktop.interface gtk-theme "$gtk" 2>/dev/null; then
    echo "FAILED: cannot write gtk-theme (no D-Bus session bus?)"
    exit 1
fi

echo "applied $THEME (color-scheme=$scheme, gtk-theme=$gtk)"
