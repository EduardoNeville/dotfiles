#!/bin/sh
# battery_percentage.sh — both battery packs, for the status bar.
#
#   battery_percentage.sh        ->  BAT0:53%|BAT1:4%
#
# This laptop has two packs (BAT0 internal + BAT1 removable). The EC normally
# drains BAT1 first and hands over to BAT0 only when BAT1 is nearly flat — so
# an aggregate (average or min) hides where the machine really is. Print every
# pack explicitly; unreadable packs are skipped, and with no readable pack at
# all we print N/A. `battery_guard.sh` is what moves the load at 10% instead
# of waiting for the EC's cutoff.
#
# (No trailing sleep: slstatus reads the output only after the script exits,
# so it would freeze the whole bar for 5 s every update instead of throttling.)

set -u

out=""
for bat in /sys/class/power_supply/BAT*/capacity; do
    [ -f "$bat" ] || continue
    capacity="$(cat "$bat" 2>/dev/null)" || continue
    case "$capacity" in ''|*[!0-9]*) continue ;; esac
    name="$(basename "$(dirname "$bat")")"   # BAT0 / BAT1
    out="${out:+$out|}${name}:${capacity}%"
done

[ -n "$out" ] && printf "%s" "$out" || printf "N/A"
