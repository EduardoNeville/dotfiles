#!/bin/bash
# gtk_theme.sh — tell the desktop which appearance the theme state asks for.
#
#   gtk_theme.sh    — read ~/.local/state/theme, write the GSettings appearance
#
# This machine has no desktop environment and no xdg-desktop-portal, so:
#
#   - GSettings (color-scheme, gtk-theme) are the STARTUP signal: Firefox and
#     GTK apps read them when they launch.
#   - xsettingsd (installed below) is the LIVE signal: Firefox/GTK3 only
#     re-evaluate an open window when an XSETTINGS manager broadcasts the
#     change. Without it, a gsettings flip is ignored by already-running apps
#     (open tabs keep their old prefers-color-scheme until restart).
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

# xsettingsd broadcasts the theme over XSETTINGS — the ONLY live theme signal
# GTK3/Firefox accept (gsettings is read once, at startup). It runs as a
# systemd user unit (written here on first use); a restart re-announces every
# property to all running GTK clients, which is what makes Firefox tabs flip
# without a reload.
#
# Key names are XSETTINGS wire names: "Net/ThemeName" maps to
# GtkSettings:gtk-theme-name. Don't use "gtk-theme-name" (xsettingsd rejects
# the hyphen) or "Gtk/ThemeName"/"Gtk/ApplicationPreferDarkTheme"/
# "Gtk/ColorScheme" (this GTK build ignores them, verified empirically).
if command -v xsettingsd >/dev/null 2>&1; then
    cat > "$HOME/.xsettingsd" <<EOF
Net/ThemeName "$gtk"
# Xft/DPI is in 1024ths of a point, which is the unit XSETTINGS uses:
# 110dpi * 1024 = 112640. It lives here because this heredoc is the single
# writer of ~/.xsettingsd — a separate script adding the key would be silently
# dropped on the next theme toggle. This is what actually scales GTK3/Firefox
# chrome: they read the XSETTINGS Xft/DPI key, whereas
# org.gnome.desktop.interface text-scaling-factor is only mapped by
# gnome-settings-daemon, which this session does not run.
Xft/DPI 112640
EOF
    UNIT="$HOME/.config/systemd/user/xsettingsd.service"
    if [ ! -f "$UNIT" ]; then
        cat > "$UNIT" <<'EOF'
[Unit]
Description=XSETTINGS daemon - live theme broadcast for GTK apps and Firefox

[Service]
Type=simple
ExecStart=/usr/bin/xsettingsd
Restart=on-failure
Environment=DISPLAY=:0
Environment=XAUTHORITY=%h/.Xauthority

[Install]
WantedBy=default.target
EOF
    fi
    systemctl --user daemon-reload 2>/dev/null || true
    systemctl --user enable xsettingsd.service >/dev/null 2>&1 || true
    if ! systemctl --user restart xsettingsd.service 2>/dev/null; then
        # no user systemd (bare startx): fall back to a detached spawn
        pkill -x xsettingsd 2>/dev/null
        setsid xsettingsd >/dev/null 2>&1 &
    fi
fi

echo "applied $THEME (color-scheme=$scheme, gtk-theme=$gtk)"
