#!/bin/bash
# Verify end-to-end theme propagation and tmux sync.
#
# Flow (on the machine it runs on):
#   1. Determine targets: every host in ~/.config/theme/remote-hosts. If none
#      are configured, fall back to verifying THIS machine (requires a running
#      tmux server — otherwise SKIP, exit 0).
#   2. Read the current theme state (default dark).
#   3. Flip the state via propagate_state.sh (writes local state, syncs local
#      tmux, pushes to all remote hosts — waited on via PROPAGATE_WAIT=1).
#   4. Assert tmux global options changed on each reachable target:
#      before/after `tmux show-options -g status-style`.
#   5. Report whether ~/.local/state/theme-sync.log grew (pi extension
#      evidence — informational only).
#   6. Restore the original theme and re-sync.
#
# Runnable on ANY machine with the dotfiles clone: a missing tmux server or a
# missing tailscale binary are reported as SKIP/notes, not fatal.
#
# Exit status: 0 when every reachable target synced and restored correctly
# (or there was nothing to verify), 1 when a reachable target failed its
# assertion.
#
# Env override: DOTFILES_SCRIPTS — path to the theme scripts dir (useful for
# verifying a checkout without installing it).

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}"
STATE_FILE="$STATE_DIR/theme"
LOG_FILE="$STATE_DIR/theme-propagate.log"
SYNC_LOG="$STATE_DIR/theme-sync.log"
REMOTE_HOSTS="${XDG_CONFIG_HOME:-$HOME/.config}/theme/remote-hosts"
REMOTE_SCRIPTS="$HOME/dotfiles/configs/theme/scripts"
LOCAL_SCRIPTS="${DOTFILES_SCRIPTS:-$REMOTE_SCRIPTS}"

# Mirror of propagate_state.sh's remote command (propagate_state.sh is the
# source of truth; keep in sync if that script changes).
_remote_cmd() {
    local theme="$1"
    local scripts="$2" # remote hosts use $HOME/dotfiles; local fallback may use an override
    printf "mkdir -p '%s' && echo '%s' > '%s' && [ -f '%s/tmux_theme_sync.sh' ] && bash '%s/tmux_theme_sync.sh'" \
        "$STATE_DIR" "$theme" "$STATE_FILE" "$scripts" "$scripts"
}

# Run <cmd> on a remote host; output captured in OUT. 0 on success.
_remote_capture() {
    local host="$1"
    local cmd="$2"
    local out=""
    if command -v tailscale &>/dev/null; then
        out=$(timeout 10 tailscale ssh "$host" "$cmd" 2>&1) && { OUT="$out"; return 0; }
    fi
    out=$(timeout 10 ssh -o ConnectTimeout=5 -o BatchMode=yes \
        -o StrictHostKeyChecking=accept-new "$host" "$cmd" 2>&1) && { OUT="$out"; return 0; }
    OUT="$out"
    return 1
}

# Run <cmd> locally; output captured in OUT. 0 on success.
_local_capture() {
    local cmd="$1"
    OUT=$(bash -c "$cmd" 2>&1) && return 0
    return 1
}

# Capture the global status-style of a target (OUT). 0 on success.
_target_status_style() {
    local target="$1"
    if [ "$target" = "__local__" ]; then
        _local_capture "tmux show-options -g -v status-style"
    else
        _remote_capture "$target" "tmux show-options -g -v status-style 2>/dev/null"
    fi
}

# Run the propagation layer for <theme> (local write + local tmux + remote push).
_run_propagate() {
    local theme="$1"
    DOTFILES_SCRIPTS="$LOCAL_SCRIPTS" PROPAGATE_WAIT=1 \
        bash "$LOCAL_SCRIPTS/propagate_state.sh" "$theme" >>"$LOG_FILE" 2>&1
}

# ── Targets ──────────────────────────────────────────────────
TARGETS=()
if [ -f "$REMOTE_HOSTS" ]; then
    while IFS= read -r host || [ -n "$host" ]; do
        case "$host" in ''|\#*) continue ;; esac
        TARGETS+=("$host")
    done < "$REMOTE_HOSTS"
fi
if [ "${#TARGETS[@]}" -eq 0 ]; then
    TARGETS+=("__local__")
fi

ORIGINAL=$(cat "$STATE_FILE" 2>/dev/null || echo "dark")
FLIPPED="light"; [ "$ORIGINAL" = "light" ] && FLIPPED="dark"

echo "verify_theme_sync: current theme='$ORIGINAL' (will flip to '$FLIPPED', then restore)"
echo "targets: ${TARGETS[*]}"

# ── Guard: local fallback needs a running tmux server ─────────
if [ "${#TARGETS[@]}" -eq 1 ] && [ "${TARGETS[0]}" = "__local__" ]; then
    if ! command -v tmux >/dev/null 2>&1 || ! tmux has-session 2>/dev/null; then
        echo "SKIP: no tmux server running here and no remote-hosts configured."
        echo "      (verify_theme_sync.sh is safe to run on any machine with the clone.)"
        exit 0
    fi
fi
if ! command -v tailscale >/dev/null 2>&1; then
    echo "NOTE: tailscale not installed — only the plain-ssh fallback will be used."
fi

# ── 1. Before: capture status-style per target ────────────────
declare -A BEFORE
declare -A REACHABLE
for t in "${TARGETS[@]}"; do
    if _target_status_style "$t"; then
        BEFORE["$t"]="$OUT"
        REACHABLE["$t"]=1
        echo "before  $t: ${OUT:-<empty>}"
    else
        BEFORE["$t"]=""
        REACHABLE["$t"]=0
        echo "before  $t: UNREACHABLE/query failed (${OUT:-})"
    fi
done

# ── 2. Flip state through the real propagation layer ──────────
SYNC_LOG_BEFORE=0
[ -f "$SYNC_LOG" ] && SYNC_LOG_BEFORE=$(wc -l < "$SYNC_LOG")
echo "flipping theme to '$FLIPPED' via propagate_state.sh ..."
if ! _run_propagate "$FLIPPED"; then
    echo "ERROR: propagate_state.sh failed (exit $?) — see $LOG_FILE"
fi
sleep 1 # let the pi extension watcher and option propagation settle

# ── 3. After: assert tmux global options changed ──────────────
PASS=0; FAIL=0; NA=0
for t in "${TARGETS[@]}"; do
    if [ "${REACHABLE[$t]:-0}" = "0" ]; then
        echo "after   $t: skipped (unreachable before)"
        FAIL=$((FAIL + 1))
        continue
    fi
    if ! _target_status_style "$t"; then
        echo "after   $t: query failed (${OUT:-})"
        NA=$((NA + 1))
        continue
    fi
    AFTER="$OUT"
    echo "after   $t: ${AFTER:-<empty>}"
    if [ -n "${BEFORE[$t]}" ] && [ -n "$AFTER" ] && [ "${BEFORE[$t]}" != "$AFTER" ]; then
        echo "ASSERT  $t: tmux global status-style CHANGED  (PASS)"
        PASS=$((PASS + 1))
    else
        echo "ASSERT  $t: tmux global status-style did NOT change  (FAIL)"
        FAIL=$((FAIL + 1))
    fi
done

# ── 4. Pi extension evidence: theme-sync.log growth ───────────
SYNC_LOG_AFTER=0
[ -f "$SYNC_LOG" ] && SYNC_LOG_AFTER=$(wc -l < "$SYNC_LOG")
if [ "$SYNC_LOG_AFTER" -gt "$SYNC_LOG_BEFORE" ]; then
    echo "pi-evidence: $SYNC_LOG grew by $((SYNC_LOG_AFTER - SYNC_LOG_BEFORE)) line(s)"
else
    echo "pi-evidence: $SYNC_LOG did NOT grow (pi TUI not running / extension not loaded / no switch seen)"
fi

# ── 5. Restore the original theme ─────────────────────────────
echo "restoring theme '$ORIGINAL' via propagate_state.sh ..."
_run_propagate "$ORIGINAL"
sleep 1
RESTORE_OK=1
for t in "${TARGETS[@]}"; do
    [ "${REACHABLE[$t]:-0}" = "0" ] && continue
    if _target_status_style "$t" && [ -n "$OUT" ] && [ "$OUT" = "${BEFORE[$t]}" ]; then
        echo "restore $t: back to '${BEFORE[$t]}' (OK)"
    else
        echo "restore $t: FAILED (now '${OUT:-?}')"
        RESTORE_OK=0
    fi
done

echo
echo "=== SUMMARY ==="
echo "pass=$PASS fail=$FAIL n/a=$NA restore_ok=$RESTORE_OK"
if [ "$FAIL" = "0" ] && [ "$RESTORE_OK" = "1" ]; then
    echo "VERIFY OK"
    exit 0
else
    echo "VERIFY FAILED — see details above and tail of $LOG_FILE"
    exit 1
fi
