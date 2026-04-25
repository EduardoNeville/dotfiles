#!/bin/bash
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}"
STATE_FILE="$STATE_DIR/theme"
THEME=$(cat "$STATE_FILE" 2>/dev/null || echo "dark")

if [ "$THEME" = "light" ]; then
    echo "dark" > "$STATE_FILE"
    tmux set -g status-style bg='#011627',fg='#d6deeb' 2>/dev/null
    tmux set -g pane-border-style fg='#1d3b53' 2>/dev/null
    tmux set -g pane-active-border-style fg='#82aaff' 2>/dev/null
    tmux set -g message-style bg='#82aaff',fg='#011627' 2>/dev/null
    tmux set -g mode-style bg='#c792ea',fg='#011627' 2>/dev/null
    tmux set -g window-status-activity-style fg='#c5e478',bg='#011627' 2>/dev/null
else
    echo "light" > "$STATE_FILE"
    tmux set -g status-style bg='#fbfbfb',fg='#403f53' 2>/dev/null
    tmux set -g pane-border-style fg='#e0e0e0' 2>/dev/null
    tmux set -g pane-active-border-style fg='#288ed7' 2>/dev/null
    tmux set -g message-style bg='#288ed7',fg='#fbfbfb' 2>/dev/null
    tmux set -g mode-style bg='#d6438a',fg='#fbfbfb' 2>/dev/null
    tmux set -g window-status-activity-style fg='#e0af02',bg='#fbfbfb' 2>/dev/null
fi