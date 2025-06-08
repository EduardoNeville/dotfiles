#!/bin/sh

# Audio
eval $(dbus-launch --sh-syntax)
export XDG_RUNTIME_DIR="/run/user/$(id -u)"
pipewire &
pipewire-pulse &
wireplumber &

# Notification script
DUNST_DIR=/home/eduardoneville/dotfiles/configs/dunst/
./$DUNST_DIR/dunst_audio &
./$DUNST_DIR/dunst_battery &
./$DUNST_DIR/dunst_bluetooth &

feh --bg-scale /home/eduardoneville/dotfiles/assets/hands_of_god.png &
picom &
dunst &
slstatus &
exec dwm
