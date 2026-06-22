#!/bin/bash
# Propagate theme state to local machine and remote SSH hosts.
# Called from Wezterm's toggle_theme() with one argument: "light" or "dark"
#
# Remote hosts are listed in ~/.config/theme/remote-hosts, one per line.
# Authentication priority:
#   1. Tailscale SSH (tailscale ssh) — requires `sudo tailscale up --ssh`
#      on the target machine (one-time setup per host).
#   2. Regular SSH keys — set up with `ssh-copy-id user@host`.

THEME="${1:-dark}"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}"
STATE_FILE="$STATE_DIR/theme"

# ── Helpers ──────────────────────────────────────────────────

# Run a command on a remote host, trying Tailscale SSH first,
# then falling back to regular SSH with key-based auth.
_remote_exec() {
    local host="$1"
    local cmd="$2"
    if command -v tailscale &>/dev/null; then
        timeout 8 tailscale ssh "$host" "$cmd" 2>/dev/null && return 0
    fi
    timeout 8 ssh -o ConnectTimeout=5 -o BatchMode=yes "$host" "$cmd" 2>/dev/null
}

# ── 1. Write locally (idempotent — Wezterm already did this) ─
mkdir -p "$STATE_DIR"
echo "$THEME" > "$STATE_FILE"

# ── 2. Sync local tmux if running inside one ─────────────────
DOTFILES_SCRIPTS="$HOME/dotfiles/configs/theme/scripts"
if [ -n "$TMUX" ] && [ -f "$DOTFILES_SCRIPTS/tmux_theme_sync.sh" ]; then
    bash "$DOTFILES_SCRIPTS/tmux_theme_sync.sh"
fi

# ── 3. Propagate to remote hosts (background, non-blocking) ──
REMOTE_HOSTS="${XDG_CONFIG_HOME:-$HOME/.config}/theme/remote-hosts"
if [ -f "$REMOTE_HOSTS" ]; then
    while IFS= read -r host || [ -n "$host" ]; do
        case "$host" in
            ''|\#*) continue ;;
        esac
        (
            _remote_exec "$host" \
                "mkdir -p $STATE_DIR && echo '$THEME' > $STATE_FILE && \
                 [ -f ~/dotfiles/configs/theme/scripts/tmux_theme_sync.sh ] && \
                 bash ~/dotfiles/configs/theme/scripts/tmux_theme_sync.sh"
        ) &
    done < "$REMOTE_HOSTS"
fi

# Backgrounded SSH processes continue after this script exits.
# We do NOT wait for them to avoid blocking Wezterm's toggle.
