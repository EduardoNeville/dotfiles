#!/bin/bash

echo "Enter which side? [left / right] :"
read  side
xrandr --output HDMI2 --auto --${side}-of eDP1

