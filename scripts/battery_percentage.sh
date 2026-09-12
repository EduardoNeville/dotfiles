#!/bin/sh

total_capacity=0
count=0

# Loop through all batteries
for bat in /sys/class/power_supply/BAT*/capacity; do
    if [ -f "$bat" ]; then
        capacity=$(cat "$bat")
        if echo "$capacity" | grep -qE '^[0-9]+$'; then
            total_capacity=$((total_capacity + capacity))
            count=$((count + 1))
        fi
    fi
done

# Calculate average percentage
if [ "$count" -gt 0 ]; then
    printf "%.0f" $((total_capacity / count))
else
    printf "N/A"
fi

sleep 5
