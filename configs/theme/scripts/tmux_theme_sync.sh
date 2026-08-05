#!/bin/bash
# Sync tmux theme from shared state file.
#
# Usage:
#   tmux_theme_sync.sh         — sync: read state, apply colors (no toggle)
#   tmux_theme_sync.sh sync    — same as above (explicit)
#   tmux_theme_sync.sh toggle  — flip state, then apply colors
#
# Callers:
#   - Wezterm's toggle_theme() via propagate_state.sh — state already updated;
#     we just read and apply (sync mode).
#   - tmux.conf hook (client-focus-in) and run-shell  — sync mode.
#   - tmux binding (Y)                                — toggle mode.
#
# `tmux set -g` / `tmux setw -g` set SERVER-WIDE options, so they work from a
# NON-tmux shell and apply to every session on the server — but only when a
# server is actually running. If no server exists we log a note and exit 0
# cleanly (nothing to update is not an error).

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}"
STATE_FILE="$STATE_DIR/theme"
APPLIED_FILE="$STATE_DIR/theme-tmux-applied"
LOG_FILE="$STATE_DIR/theme-propagate.log"

MODE="${1:-sync}"

_log() {
    printf '%s [tmux-sync] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG_FILE"
}

# ── Handle toggle mode (called from tmux binding) ──────────────
# Flip the state file first so the shared state stays consistent even when
# no tmux server is running.
if [ "$MODE" = "toggle" ]; then
    CURRENT=$(cat "$STATE_FILE" 2>/dev/null || echo "dark")
    if [ "$CURRENT" = "light" ]; then
        echo "dark" > "$STATE_FILE"
    else
        echo "light" > "$STATE_FILE"
    fi
fi

# ── Guard: only proceed when a tmux server is running ─────────
if ! command -v tmux >/dev/null 2>&1; then
    _log "tmux not installed; skipping sync"
    exit 0
fi
mkdir -p "$STATE_DIR"
if ! tmux has-session 2>/dev/null; then
    _log "no tmux server running; skipping sync"
    exit 0
fi

THEME=$(cat "$STATE_FILE" 2>/dev/null || echo "dark")

# ── Skip re-apply when the theme is already applied ───────────
# The client-focus-in hook fires on every focus change; re-applying identical
# options is wasteful and would spam the log. A genuine flip (toggle mode or a
# changed state file) always re-applies.
if [ "$MODE" != "toggle" ] && [ -f "$APPLIED_FILE" ] && [ "$(cat "$APPLIED_FILE" 2>/dev/null)" = "$THEME" ]; then
    exit 0
fi

TMUX_POWERSLINE_LEFT=""
TMUX_POWERSLINE_RIGHT=""
TMUX_SEPARATOR=""

if [ "$THEME" = "light" ]; then
    # ── Light mode (Catppuccin Latte-inspired) ──────────────
    # Background: off-white #FAFAFA, foreground: near-black #1A1A2E

    # Status bar base — text in black (#1A1A2E was hard to read as gray)
    tmux set -g status-style bg='#FAFAFA',fg='#000000'

    # Left status: [Session] [Hostname] [Git Branch]
    tmux set -g status-left ""
    tmux set -ga status-left "#[fg=#FAFAFA,bg=#1E66F5,bold] #S #[fg=#1E66F5,bg=#E6E9EF,nobold]${TMUX_POWERSLINE_LEFT}"
    tmux set -ga status-left "#[fg=#1E66F5,bg=#E6E9EF] 󰌢 #h #[fg=#E6E9EF,bg=#FAFAFA]${TMUX_POWERSLINE_LEFT}"
    tmux set -ga status-left "#[fg=#8839EF,bg=#FAFAFA] 󰘬 #(cd '#{pane_current_path}' && git branch --show-current 2>/dev/null || echo 'N/A') "

    # Window status — inactive window names in black (was #9CA0B0 gray)
    tmux setw -g window-status-format "#[fg=#000000,bg=#FAFAFA] #I ${TMUX_SEPARATOR} #W #{?window_zoomed_flag,󰊓 ,}"
    tmux setw -g window-status-current-format "#[fg=#FAFAFA,bg=#8839EF]${TMUX_POWERSLINE_LEFT}#[fg=#FAFAFA,bg=#8839EF,bold] #I #[fg=#8839EF,bg=#1E66F5]${TMUX_POWERSLINE_LEFT}#[fg=#FAFAFA,bg=#1E66F5] #W #{?window_zoomed_flag,󰊓 ,}#[fg=#1E66F5,bg=#FAFAFA]${TMUX_POWERSLINE_LEFT}"

    # Right status
    tmux set -g status-right ""
    tmux set -ga status-right "#[fg=#DF8E1D,bg=#FAFAFA]#{?#{SSH_CLIENT}, 󰌘 SSH ,}"
    tmux set -ga status-right "#[fg=#40A02B,bg=#FAFAFA] #{?#{==:#(tailscale status --json 2>/dev/null | jq -r '.Self.Online' 2>/dev/null),true},󰱠 CONNECTED,󰅙 OFFLINE} "

    # Pane borders
    tmux set -g pane-border-style fg='#E6E9EF'
    tmux set -g pane-active-border-style fg='#1E66F5'

    # Messages
    tmux set -g message-style bg='#1E66F5',fg='#FAFAFA'
    tmux set -g message-command-style bg='#E6E9EF',fg='#000000'

    # Mode (copy-mode, etc.)
    tmux setw -g mode-style bg='#8839EF',fg='#FAFAFA'

    # Activity & Bell
    tmux setw -g window-status-activity-style fg='#DF8E1D',bg='#FAFAFA'
    tmux setw -g window-status-bell-style fg='#D20F39',bg='#FAFAFA',bold

else
    # ── Dark mode (Night Owl) ───────────────────────────────
    # Background: deep navy #011627, foreground: ice blue #d6deeb

    # Status bar base
    tmux set -g status-style bg='#011627',fg='#d6deeb'

    # Left status
    tmux set -g status-left ""
    tmux set -ga status-left "#[fg=#011627,bg=#82aaff,bold] #S #[fg=#82aaff,bg=#0b2942,nobold]${TMUX_POWERSLINE_LEFT}"
    tmux set -ga status-left "#[fg=#82aaff,bg=#0b2942] 󰌢 #h #[fg=#0b2942,bg=#011627]${TMUX_POWERSLINE_LEFT}"
    tmux set -ga status-left "#[fg=#c792ea,bg=#011627] 󰘬 #(cd '#{pane_current_path}' && git branch --show-current 2>/dev/null || echo 'N/A') "

    # Window status
    tmux setw -g window-status-format "#[fg=#565f89,bg=#011627] #I ${TMUX_SEPARATOR} #W #{?window_zoomed_flag,󰊓 ,}"
    tmux setw -g window-status-current-format "#[fg=#011627,bg=#c792ea]${TMUX_POWERSLINE_LEFT}#[fg=#011627,bg=#c792ea,bold] #I #[fg=#c792ea,bg=#82aaff]${TMUX_POWERSLINE_LEFT}#[fg=#011627,bg=#82aaff] #W #{?window_zoomed_flag,󰊓 ,}#[fg=#82aaff,bg=#011627]${TMUX_POWERSLINE_LEFT}"

    # Right status
    tmux set -g status-right ""
    tmux set -ga status-right "#[fg=#c5e478,bg=#011627]#{?#{SSH_CLIENT}, 󰌘 SSH ,}"
    tmux set -ga status-right "#[fg=#22da6e,bg=#011627] #{?#{==:#(tailscale status --json 2>/dev/null | jq -r '.Self.Online' 2>/dev/null),true},󰱠 CONNECTED,󰅙 OFFLINE} "

    # Pane borders
    tmux set -g pane-border-style fg='#1d3b53'
    tmux set -g pane-active-border-style fg='#82aaff'

    # Messages
    tmux set -g message-style bg='#82aaff',fg='#011627'
    tmux set -g message-command-style bg='#0b2942',fg='#d6deeb'

    # Mode
    tmux setw -g mode-style bg='#c792ea',fg='#011627'

    # Activity & Bell
    tmux setw -g window-status-activity-style fg='#c5e478',bg='#011627'
    tmux setw -g window-status-bell-style fg='#ef5350',bg='#011627',bold

fi

# ── Record what we applied ────────────────────────────────────
# Only record the applied state when the tmux client actually worked and the
# apply landed. A nested tmux client spawned from inside a run-shell can fail
# ("server exited unexpectedly"); if we wrote the applied theme regardless, the
# dedupe at the top would later SKIP a legitimate external sync (wezterm's
# propagate_state.sh) and leave tmux stuck on the wrong theme. Probing
# show-options keeps the marker honest and self-heals across runs.
if tmux show-options -g status-style >/dev/null 2>&1; then
    SESSIONS=$(tmux list-sessions -F '#{session_name}' 2>/dev/null | wc -l)
    echo "$THEME" > "$APPLIED_FILE"
    _log "applied '$THEME' to tmux ($SESSIONS session(s))"
else
    _log "WARN: tmux client unavailable/failed; NOT recording applied theme (state stays '$THEME')"
    exit 1
fi
