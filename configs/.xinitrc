#!/bin/sh

# Notifications (systemd's battery-notify.timer feeds it warnings)
dunst &

# ClipMenu
clipmenud &

# Background
feh --bg-scale /home/eduardoneville/dotfiles/assets/plain_ascii_void.png &

# Keyboard
setxkbmap ch fr

picom &
slstatus &
exec dwm
