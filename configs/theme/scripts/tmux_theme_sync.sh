#!/bin/bash
# Sync tmux theme from shared state file.
#
# Usage:
#   tmux_theme_sync.sh         — sync: read state, apply colors (no toggle)
#   tmux_theme_sync.sh sync    — same as above (explicit)
#   tmux_theme_sync.sh toggle  — flip state, then apply colors
#
# Callers:
#   - propagate_state.sh (local, and over ssh on remote hosts) — the state file
#     is already updated, we just read and apply (sync mode).
#   - `tmux_theme_sync.sh toggle` by hand — flips the state, then applies.
#   - verify_theme_sync.sh, via propagate_state.sh.
#
# The tmux BINARY matters as much as the socket: a non-interactive shell
# (wezterm's spawned bash, `ssh host <cmd>`) does not source ~/.zshrc, so it can
# resolve the distro tmux while the running server is the source build — that
# mismatch dies with "server exited unexpectedly". Hence the explicit
# preference order below.
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

# ── Target the user's default tmux server ──────────────────────
# The caller (e.g. wezterm's run_child_process) may inherit a stale or foreign
# $TMUX (pointing at a dead/mismatched socket), which makes the nested `tmux`
# client fail to find the running server and log "no tmux server running; \
# skipping sync" — leaving tmux stuck on the old theme. We manage the default
# tmux server (socket /tmp/tmux-$UID/default), so drop the inherited TMUX/
# TMUX_TMPDIR and let `tmux` discover the canonical default socket.
unset TMUX TMUX_TMPDIR

# ── Resolve the live tmux server socket ─────────────────┬───
# The caller (e.g. wezterm's run_child_process) can inject a stale $TMUX or a
# $TMPDIR/$TMUX_TMPDIR pointing at its own runtime dir, which makes `tmux` look
# in the wrong place and fail has-session ("no tmux server running; skipping
# sync") even though a server is up. We manage the default tmux server, so find
# its actual socket file and force `tmux -S` — immune to inherited env.
_TMUX_SOCK=""
for _base in \
    "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/tmux" "${TMPDIR:-/tmp}" /tmp; do
    for _cand in "$_base/tmux-$(id -u)/default" "$_base/tmux-$(id -u)/"*/ \
                 "$_base/tmux/default" "$_base/tmux/"*; do
        if [ -S "$_cand" ] 2>/dev/null; then
            _TMUX_SOCK="$_cand"
            break 2
        fi
    done
    [ -n "$_TMUX_SOCK" ] && break
 done

# ── Resolve the tmux client binary ────────────────────────────
# The running server may be the source build ($HOME/pkgs/bin/tmux) while a
# non-interactive shell (wezterm's spawned bash, ssh command execution — neither
# sources ~/.zshrc) resolves the distro client instead. A 3.5a client against a
# 3.7b server fails with "server exited unexpectedly", so prefer the source
# build explicitly instead of trusting PATH.
TMUX_BIN=""
for _cand in "$HOME/pkgs/bin/tmux" "$HOME/.local/bin/tmux" "$(command -v tmux 2>/dev/null)"; do
    if [ -n "$_cand" ] && [ -x "$_cand" ]; then
        TMUX_BIN="$_cand"
        break
    fi
done

# Route every `tmux` call below through the resolved binary and socket.
tmux() {
    if [ -n "$_TMUX_SOCK" ]; then
        command "$TMUX_BIN" -S "$_TMUX_SOCK" "$@"
    else
        command "$TMUX_BIN" "$@"
    fi
}

# ── Guard: only proceed when a tmux server is running ─────────
if [ -z "$TMUX_BIN" ]; then
    _log "tmux not installed; skipping sync"
    exit 0
fi
mkdir -p "$STATE_DIR"
if ! tmux has-session 2>/tmp/theme-hs.err; then
    _log "no tmux server running; skipping sync (socket=${_TMUX_SOCK:-<not-found>})"
    _log "  tmux error: $(head -c 300 /tmp/theme-hs.err 2>/dev/null | tr '\n' ' ')"
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
