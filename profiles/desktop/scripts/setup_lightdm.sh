#!/usr/bin/env bash
# setup_lightdm.sh — configure lightdm + slick-greeter as the login screen and
# light-locker's lock screen. Idempotent; re-run after any lightdm upgrade.
#
# No-op when lightdm/slick-greeter are not installed: this box's login screen is
# the tty1 password prompt + startx until you install them.
#
#   1. /etc/lightdm/lightdm.conf.d/50-dotfiles.conf — select slick-greeter, and
#      make the dwm session the default (user-session)
#   2. ~/.dmrc                                      — pin the remembered session
#      to dwm as well; a session picked in the greeter is written here and
#      outranks user-session
#   3. /etc/lightdm/slick-greeter.conf              — symlink to the generated
#      state file, so greeter_theme.sh retints login AND lock screen on every
#      light/dark toggle without root
#
# Why 2 exists: /usr/share/xsessions/ also ships Debian's "Default Xsession"
# (lightdm-xsession.desktop). Picking it — or letting the greeter default to the
# first alphabetical *Name*, "Default Xsession" before "dwm" — runs
# /etc/X11/Xsession, which with no ~/.xsession and no x-session-manager falls
# back to x-terminal-emulator. On this box that is wezterm, launched unmanaged:
# no window manager, no bar, one wrongly sized terminal. That is exactly what
# happened on 2026-09-15, so the session is now pinned in both places.
#
# The session itself is /usr/share/xsessions/dwm.desktop (written by
# profiles/desktop/scripts/build_suckless.sh as Exec=/usr/local/bin/dwm-session
# -> profiles/desktop/configs/dwm-session.sh).

set -e

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}"

# /usr/sbin is not in a normal user's PATH, so test the paths directly.
if [ ! -x /usr/sbin/lightdm ] || [ ! -x /usr/sbin/slick-greeter ]; then
    echo "lightdm/slick-greeter not installed — skipping."
    echo "  install with: sudo apt install lightdm slick-greeter light-locker"
    exit 0
fi

echo "→ Configuring lightdm + slick-greeter"

sudo mkdir -p /etc/lightdm/lightdm.conf.d
sudo tee /etc/lightdm/lightdm.conf.d/50-dotfiles.conf >/dev/null <<'EOF'
# Managed by dotfiles (profiles/desktop/scripts/setup_lightdm.sh)
[Seat:*]
greeter-session=slick-greeter
user-session=dwm
EOF

# A session chosen in the greeter is remembered here and beats user-session, so
# pin it too — otherwise a single wrong pick sticks for every later login.
if ! grep -qs '^Session=dwm$' "$HOME/.dmrc"; then
    _old="$(grep -hs '^Session=' "$HOME/.dmrc" 2>/dev/null || true)"
    printf '[Desktop]\nSession=dwm\n' >"$HOME/.dmrc"
    echo "  ✓ ~/.dmrc: Session=dwm${_old:+ (was: ${_old#Session=})}"
else
    echo "  ✓ ~/.dmrc already pins Session=dwm"
fi

bash "${DOTFILES_DIR}/configs/theme/scripts/greeter_theme.sh"
sudo ln -sf "${STATE_DIR}/slick-greeter.conf" /etc/lightdm/slick-greeter.conf

echo "  ✓ greeter-session=slick-greeter, user-session=dwm"
echo "  ✓ /etc/lightdm/slick-greeter.conf -> ${STATE_DIR}/slick-greeter.conf"
echo "    (login and lock screen follow Ctrl+Shift+Y)"
echo
echo "Enable it, then reboot:   sudo systemctl enable lightdm"
