#!/bin/bash
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}"
STATE_FILE="$STATE_DIR/theme"
THEME=$(cat "$STATE_FILE" 2>/dev/null || echo "dark")

if [ "$THEME" = "light" ]; then
    echo "dark" > "$STATE_FILE"
    tmux set -g status-style bg='#1f2335',fg='#a9b1d6' 2>/dev/null
    tmux set -g pane-border-style fg='#3b4261' 2>/dev/null
    tmux set -g pane-active-border-style fg='#0969da' 2>/dev/null
    tmux set -g message-style bg='#0969da',fg='#ffffff' 2>/dev/null
    tmux set -g mode-style bg='#f0268f',fg='#ffffff' 2>/dev/null
    tmux set -g window-status-activity-style fg='#f1d751',bg='#1f2335' 2>/dev/null
else
    echo "light" > "$STATE_FILE"
    tmux set -g status-style bg='#ffffff',fg='#383a42' 2>/dev/null
    tmux set -g pane-border-style fg='#e4e4e4' 2>/dev/null
    tmux set -g pane-active-border-style fg='#0969da' 2>/dev/null
    tmux set -g message-style bg='#0969da',fg='#ffffff' 2>/dev/null
    tmux set -g mode-style bg='#e45649',fg='#ffffff' 2>/dev/null
    tmux set -g window-status-activity-style fg='#cc8800',bg='#ffffff' 2>/dev/null
fi