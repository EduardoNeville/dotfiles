#!/bin/bash
# Propagate theme state to local machine and remote SSH hosts.
# Called from Wezterm's toggle_theme() with one argument: "light" or "dark"
#
# Remote hosts are listed in ~/.config/theme/remote-hosts, one per line.
# Blank lines and # comments are ignored.
# Uses Tailscale SSH (tailscale ssh) for authentication.
# Regular SSH can also be used — swap tailscale ssh for ssh.

THEME="${1:-dark}"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}"
STATE_FILE="$STATE_DIR/theme"

# 1. Write locally (idempotent — Wezterm already did this)
mkdir -p "$STATE_DIR"
echo "$THEME" > "$STATE_FILE"

# 2. Sync local tmux if running inside one
if [ -n "$TMUX" ] && [ -f "$HOME/.config/theme/scripts/tmux_theme_sync.sh" ]; then
    bash "$HOME/.config/theme/scripts/tmux_theme_sync.sh"
fi

# 3. Propagate to remote hosts (background, non-blocking)
REMOTE_HOSTS="$HOME/.config/theme/remote-hosts"
if [ -f "$REMOTE_HOSTS" ]; then
    while IFS= read -r host || [ -n "$host" ]; do
        # Skip blank lines and comments
        case "$host" in
            ''|\#*) continue ;;
        esac
        (
            timeout 5 tailscale ssh "$host" \
                "mkdir -p $STATE_DIR && echo '$THEME' > $STATE_FILE && \
                 [ -f ~/.config/theme/scripts/tmux_theme_sync.sh ] && \
                 bash ~/.config/theme/scripts/tmux_theme_sync.sh" \
                2>/dev/null
        ) &
    done < "$REMOTE_HOSTS"
fi

# Note: backgrounded SSH processes continue after this script exits.
# We do NOT wait for them to avoid blocking Wezterm's toggle.
