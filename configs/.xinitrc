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
DUNST_DIR=/home/eduardoneville/dotfiles/configs/dunst/
./$DUNST_DIR/dunst_audio &
./$DUNST_DIR/dunst_battery &
./$DUNST_DIR/dunst_bluetooth &

# ClipMenu
clipmenud &

# Background
feh --bg-scale /home/eduardoneville/dotfiles/assets/hands_of_god.png &

# Keyboard
setxkbmap ch fr

picom &
slstatus &
exec dwm
