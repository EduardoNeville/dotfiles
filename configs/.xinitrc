#!/bin/sh

# Notification script
dunst &
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
