#!/bin/bash
# Propagate theme state to local machine and remote SSH hosts.
# Called from Wezterm's toggle_theme() with one argument: "light" or "dark"
#
# Remote hosts are listed in ~/.config/theme/remote-hosts, one per line.
# Authentication priority:
#   1. Tailscale SSH (tailscale ssh) — requires `sudo tailscale up --ssh`
#      on the target machine (one-time setup per host; see
#      configs/theme/scripts/setup_theme_remotes.sh).
#   2. Regular SSH keys — one-time setup: `ssh-copy-id <user>@<host>` and
#      `ssh-keyscan <host> >> ~/.ssh/known_hosts`. The fallback connects with
#      StrictHostKeyChecking=accept-new so a freshly-scanned host key is
#      trusted without manual known_hosts edits.
#
# Logging: every run appends a timestamped entry to
#   ~/.local/state/theme-propagate.log
# (local write, tmux sync, per-host attempts/failures). Wezterm invokes this
# non-interactively with zero feedback today, so the log is the only record.
#
# Env overrides:
#   DOTFILES_SCRIPTS  — path to the theme scripts dir (default
#                       $HOME/dotfiles/configs/theme/scripts). Mainly useful
#                       for testing a checkout without installing it.
#   PROPAGATE_WAIT    — set to 1 to wait for the backgrounded remote SSH jobs
#                       to finish (used by verify_theme_sync.sh). Wezterm must
#                       stay non-blocking, so the default is 0.

THEME="${1:-dark}"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}"
STATE_FILE="$STATE_DIR/theme"
LOG_FILE="$STATE_DIR/theme-propagate.log"
DOTFILES_SCRIPTS="${DOTFILES_SCRIPTS:-$HOME/dotfiles/configs/theme/scripts}"

mkdir -p "$STATE_DIR"

_log() {
    printf '%s [propagate] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG_FILE"
}

# Remote command run on each host: write the state file, then sync tmux.
# Remote hosts are expected to have the dotfiles clone at $HOME/dotfiles.
_remote_cmd() {
    local theme="$1"
    local remote_scripts="$HOME/dotfiles/configs/theme/scripts"
    printf "mkdir -p '%s' && echo '%s' > '%s' && [ -f '%s/tmux_theme_sync.sh' ] && bash '%s/tmux_theme_sync.sh'" \
        "$STATE_DIR" "$theme" "$STATE_FILE" "$remote_scripts" "$remote_scripts"
}

# Run a command on a remote host, trying Tailscale SSH first, then falling
# back to regular SSH with key-based auth. Every attempt and its outcome is
# appended to the log; errors are never sent to /dev/null.
_remote_exec() {
    local host="$1"
    local cmd="$2"
    local out="" last=""

    if command -v tailscale &>/dev/null; then
        out=$(timeout 8 tailscale ssh "$host" "$cmd" 2>&1)
        if [ $? -eq 0 ]; then
            _log "host '$host': tailscale ssh OK"
            return 0
        fi
        last=$(printf '%s\n' "$out" | tail -1 | tr -d '\r')
        _log "host '$host': tailscale ssh failed (${last:-no output}); trying plain ssh"
    fi

    out=$(timeout 8 ssh -o ConnectTimeout=5 -o BatchMode=yes \
        -o StrictHostKeyChecking=accept-new "$host" "$cmd" 2>&1)
    if [ $? -eq 0 ]; then
        _log "host '$host': plain ssh OK"
        return 0
    fi
    last=$(printf '%s\n' "$out" | tail -1 | tr -d '\r')
    _log "host '$host': plain ssh FAILED (${last:-no output})"
    return 1
}

# ── 1. Write locally (idempotent — Wezterm already did this) ─
if [ -n "$TMUX" ]; then FROM="inside tmux"; else FROM="non-tmux shell"; fi
_log "run theme='$THEME' (from $FROM)"
echo "$THEME" > "$STATE_FILE"
_log "local state written: '$THEME' -> $STATE_FILE"

# ── 2. Sync local tmux (server-wide; safe from any shell) ─────
# No "$TMUX" check needed: the sync script itself guards for a running
# server and exits 0 with a log note when there is none.
if [ -f "$DOTFILES_SCRIPTS/tmux_theme_sync.sh" ]; then
    if bash "$DOTFILES_SCRIPTS/tmux_theme_sync.sh"; then
        _log "tmux sync: OK"
    else
        _log "tmux sync: FAILED (exit $?)"
    fi
else
    _log "tmux sync: skipped (script not found: $DOTFILES_SCRIPTS/tmux_theme_sync.sh)"
fi

# ── 3. Propagate to remote hosts (background, non-blocking) ──
REMOTE_HOSTS="${XDG_CONFIG_HOME:-$HOME/.config}/theme/remote-hosts"
if [ -f "$REMOTE_HOSTS" ]; then
    while IFS= read -r host || [ -n "$host" ]; do
        case "$host" in
            ''|\#*) continue ;;
        esac
        # Backgrounded SSH processes continue after this script exits.
        # We do NOT wait for them so Wezterm's toggle stays non-blocking.
        # All output lands in the log, never /dev/null.
        (
            _remote_exec "$host" "$(_remote_cmd "$THEME")"
        ) >>"$LOG_FILE" 2>&1 &
    done < "$REMOTE_HOSTS"
    if [ "${PROPAGATE_WAIT:-0}" = "1" ]; then
        wait
        _log "remote propagation finished (PROPAGATE_WAIT=1)"
    fi
else
    _log "no remote-hosts file ($REMOTE_HOSTS); remote propagation skipped"
fi
