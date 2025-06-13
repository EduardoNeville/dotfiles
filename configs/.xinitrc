#!/bin/sh

# Audio
eval $(dbus-launch --sh-syntax)
export XDG_RUNTIME_DIR="/run/user/$(id -u)"
sudo mkdir -p $XDG_RUNTIME_DIR
sudo chmod 700 $XDG_RUNTIME_DIR
pipewire &
pipewire-pulse &
wireplumber &

# Notification script
dunst &
dunst_audio &
dunst_battery &
dunst_bluetooth &

# ClipMenu
clipmenud &

# Background
feh --bg-scale /home/eduardoneville/dotfiles/assets/plain_ascii_void.png &

# Keyboard
setxkbmap ch fr

picom &
slstatus &
exec dwm
