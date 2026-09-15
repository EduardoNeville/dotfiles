#!/usr/bin/env bash
# setup_lightdm.sh — configure lightdm + slick-greeter as the login screen and
# light-locker's lock screen. Idempotent; re-run after any lightdm upgrade.
#
# No-op when lightdm/slick-greeter are not installed: this box's login screen is
# the tty1 password prompt + startx until you install them.
#
#   1. /etc/lightdm/lightdm.conf.d/50-dotfiles.conf — select slick-greeter
#   2. /etc/lightdm/slick-greeter.conf              — symlink to the generated
#      state file, so greeter_theme.sh retints login AND lock screen on every
#      light/dark toggle without root
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
EOF

bash "${DOTFILES_DIR}/configs/theme/scripts/greeter_theme.sh"
sudo ln -sf "${STATE_DIR}/slick-greeter.conf" /etc/lightdm/slick-greeter.conf

echo "  ✓ greeter-session=slick-greeter"
echo "  ✓ /etc/lightdm/slick-greeter.conf -> ${STATE_DIR}/slick-greeter.conf"
echo "    (login and lock screen follow Ctrl+Shift+Y)"
echo
echo "Enable it, then reboot:   sudo systemctl enable lightdm"
