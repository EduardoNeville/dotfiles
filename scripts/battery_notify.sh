#!/bin/sh

while true; do
    total_capacity=0
    count=0
    discharging=false

    # Check all batteries
    for bat in /sys/class/power_supply/BAT*/capacity; do
        if [ -f "$bat" ]; then
            capacity=$(cat "$bat")
            status=$(cat "${bat%/capacity}/status")
            if echo "$capacity" | grep -qE '^[0-9]+$'; then
                total_capacity=$((total_capacity + capacity))
                count=$((count + 1))
            fi
            [ "$status" = "Discharging" ] && discharging=true
        fi
    done

    # Calculate average percentage
    if [ "$count" -gt 0 ]; then
        percentage=$((total_capacity / count))
    else
        percentage="N/A"
    fi

    # If discharging and percentage is numeric, check thresholds
    if [ "$discharging" = true ] && [ "$percentage" != "N/A" ]; then
        if [ "$percentage" -lt 20 ] && [ ! -f /tmp/battery_20_notified ]; then
            dunstify "Battery low: $percentage%"
            touch /tmp/battery_20_notified
        fi
        if [ "$percentage" -lt 10 ] && [ ! -f /tmp/battery_10_notified ]; then
            dunstify "Battery very low: $percentage%"
            touch /tmp/battery_10_notified
        fi
        if [ "$percentage" -lt 5 ] && [ ! -f /tmp/battery_5_notified ]; then
            dunstify -u critical "Battery critically low: $percentage%"
            touch /tmp/battery_5_notified
        fi
    else
        # Reset notification flags if charging or no valid data
        rm -f /tmp/battery_*_notified
    fi

    # Wait 60 seconds
    sleep 60
done
