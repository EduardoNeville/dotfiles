#!/bin/sh
# battery_percentage.sh — lowest battery level, for the status bar.
#
#   battery_percentage.sh
#
# Prints the *minimum* across all batteries, not the average. This laptop has
# two packs (BAT0 internal + BAT1 removable) and the EC drains BAT0 first; when
# BAT0 reaches true empty the EC cuts power instead of handing over to BAT1.
# Averaging the two reads ~50% while the pack that actually powers the machine
# is empty — the minimum is the number that predicts a shutdown.
#
# The sleep keeps the caller (slstatus, 1 s interval) from re-forking every
# second; the value itself is printed immediately.

set -u

min=""
for bat in /sys/class/power_supply/BAT*/capacity; do
    [ -f "$bat" ] || continue
    capacity="$(cat "$bat" 2>/dev/null)" || continue
    case "$capacity" in ''|*[!0-9]*) continue ;; esac
    if [ -z "$min" ] || [ "$capacity" -lt "$min" ]; then
        min="$capacity"
    fi
done

if [ -n "$min" ]; then
    printf "%s" "$min"
else
    printf "N/A"
fi

sleep 5
