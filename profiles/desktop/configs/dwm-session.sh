#!/usr/bin/env sh
# dwm session definition — the ONE place the session's daemons are listed.
#
# Two entry points run this:
#   - startx (tty1 fallback): ~/.xinitrc execs it
#   - lightdm (login + lock): /usr/share/xsessions/dwm.desktop execs
#                             /usr/local/bin/dwm-session, a symlink installed by
#                             profiles/desktop/scripts/build_suckless.sh
# A display manager runs the .desktop Exec= verbatim, so without this split a
# DM session would be a bare dwm: no bar, no notifications, no wallpaper.

# Wallpaper (feh ships with desktop packages; wallpapers in dotfiles/assets)
[ -f "${DOTFILES_DIR:-$HOME/dotfiles}/assets/hands_of_god.png" ] && \
    feh --bg-fill "${DOTFILES_DIR:-$HOME/dotfiles}/assets/hands_of_god.png" &

# Status bar + notifications (dwm's config.h does not spawn these)
command -v slstatus >/dev/null 2>&1 && slstatus &
command -v dunst >/dev/null 2>&1 && dunst &

# Clipboard daemon (clipmenud records the store; dwm mod+shift+v = clipmenu)
command -v clipmenud >/dev/null 2>&1 && clipmenud &

# Polkit auth agent (required by gparted/blueman/nm-applet root auth prompts)
[ -x /usr/lib/polkit-kde-authentication-agent-1 ] && \
    /usr/lib/polkit-kde-authentication-agent-1 &

# Screen locker. Its lock screen IS the lightdm greeter (slick-greeter), so
# login and resume look the same. --lock-on-suspend covers suspend AND
# hibernate: both are logind sleep events. No idle locking by design — the
# `xset s off -dpms` below disables the X screensaver entirely.
command -v light-locker >/dev/null 2>&1 && light-locker --lock-on-suspend &

# No system tray (dwm has none); wifi config via nmtui, bluetooth via
# blueman-manager, both are on-demand window apps.

command -v xset >/dev/null 2>&1 && xset s off -dpms &

# Prefer the dwm built from this repo over /usr/local/bin/dwm. The source tree
# is the source of truth, and on 2026-09-15 a stale installed binary (the fix
# was built but `make install` had not run) deadlocked the session on the first
# Ctrl+Shift+Y. `make install` still updates /usr/local/bin/dwm for other
# consumers; this only decides which one the session runs.
DWM_BIN="${DOTFILES_DIR:-$HOME/dotfiles}/profiles/desktop/configs/suckless/dwm/dwm"
[ -x "$DWM_BIN" ] || DWM_BIN=dwm
exec "$DWM_BIN"
