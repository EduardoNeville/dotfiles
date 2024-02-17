#!/bin/bash

bluetoothctl power on

bluetoothctl devices

echo "Copy and paste the mac address of the device you want to use! \n"
echo "Input: "
read device

bluetoothctl connect ${device}
