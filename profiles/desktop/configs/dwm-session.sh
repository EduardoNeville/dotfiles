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

# X resources — the panel is 157dpi (31cm at 1920px) but X clients default to
# 96dpi, so dwm's bar, dmenu, rofi and GTK chrome all rendered physically
# smaller than wezterm (which auto-detects the panel). Xft.dpi=110 brings them
# back in line. dwm opens its fonts once, at startup, so this must run before
# the exec at the bottom.
XRES="${DOTFILES_DIR:-$HOME/dotfiles}/profiles/desktop/configs/Xresources"
[ -f "$XRES" ] && command -v xrdb >/dev/null 2>&1 && xrdb -merge "$XRES"

# Wallpaper — theme-aware: wallpaper.sh reads the state file and picks the
# asset, so the same mapping is used here and on every toggle.
[ -f "${DOTFILES_DIR:-$HOME/dotfiles}/configs/theme/scripts/wallpaper.sh" ] && \
    bash "${DOTFILES_DIR:-$HOME/dotfiles}/configs/theme/scripts/wallpaper.sh" >/dev/null 2>&1 &

# apply stored theme and start xsettingsd: the live appearance signal for
# already-running GTK apps and Firefox (see gtk_theme.sh)
[ -f "${DOTFILES_DIR:-$HOME/dotfiles}/configs/theme/scripts/gtk_theme.sh" ] && \
    bash "${DOTFILES_DIR:-$HOME/dotfiles}/configs/theme/scripts/gtk_theme.sh" >/dev/null 2>&1 &

# Firefox page scale — stored in each profile's user.js, because Firefox
# creates and names its profiles (nothing to symlink). install.sh writes it
# once; this re-run is what catches a profile that appears afterwards. Writes
# only when the marked block is missing or stale, so it is silent after the
# first login.
[ -x "${DOTFILES_DIR:-$HOME/dotfiles}/profiles/desktop/scripts/firefox_legibility.sh" ] && \
    "${DOTFILES_DIR:-$HOME/dotfiles}/profiles/desktop/scripts/firefox_legibility.sh" >/dev/null 2>&1 &

# Compositor — exists to kill X11 tearing (glx + vsync, no effects). The config
# is passed explicitly rather than relying on ~/.config/picom being linked, so
# the session cannot silently fall back to built-in defaults (no vsync).
command -v picom >/dev/null 2>&1 && \
    picom -b --config "${DOTFILES_DIR:-$HOME/dotfiles}/configs/picom/picom.conf" &

# Brightness — two things overwrite the panel state behind our back: picom
# installs an identity gamma LUT when it starts (-b means it may still be
# starting), and systemd-backlight restored whatever percentage was saved at
# the last shutdown (36% here). light.sh restore re-applies the user's saved
# level, curve and vibrance; the short delay lets picom win the race first.
(
    sleep 1
    "${DOTFILES_DIR:-$HOME/dotfiles}/profiles/desktop/scripts/light.sh" restore
) >/dev/null 2>&1 &

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
