static const struct arg args[] = {
    /* Use upower to get combined battery percentage and remaining time */
    { run_command, "[BAT:%s|", "upower -i $(upower -e | grep 'BAT' | head -n 1) | grep -E 'percentage|time to empty' | awk '{print $2}' | tr '\n' ' ' | sed 's/ hours/h/'" },
    { ram_perc, "RAM: %s%% ", NULL },
    { datetime, "%s", "%Y-%m-%d %H:%M" },
};
