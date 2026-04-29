#!/usr/bin/env bash
# opencode-notify-test.sh
#
# Test that OSC 9 notification sequences propagate through your terminal stack.
# Tries multiple delivery paths to diagnose where the chain might be broken.
#
# Propagation options tested:
#   1. Direct SSH pty write (bypasses tmux — most reliable for SSH sessions)
#   2. Tmux DCS passthrough wrapper (through tmux's allow-passthrough protocol)
#   3. Raw OSC 9 to stdout (works when NOT in tmux)
#
# Usage:
#   bash ~/dotfiles/scripts/opencode-notify-test.sh
#
# Expected: a desktop notification appears on your local machine
#           titled "opencode" with a test message.

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

banner() {
    echo ""
    echo -e "${BOLD}${CYAN}════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${CYAN}  OpenCode Notification Chain Test${NC}"
    echo -e "${BOLD}${CYAN}════════════════════════════════════════════════════════${NC}"
    echo ""
}

section() {
    echo -e "${BOLD}── $1 ──${NC}"
}

banner

# ── Environment Diagnostics ──────────────────────────────────────────
section "Environment"

echo -n "  Terminal:          "
if [ -n "$TERM_PROGRAM" ]; then
    echo -e "${GREEN}$TERM_PROGRAM${NC}"
elif [ -n "$TERM" ]; then
    echo -e "${GREEN}$TERM${NC}"
else
    echo -e "${YELLOW}unknown${NC}"
fi

echo -n "  Inside tmux?       "
if [ -n "$TMUX" ]; then
    # shellcheck disable=SC2154
    echo -e "${GREEN}yes (session: ${TMUX#*/})${NC}"
else
    echo -e "${YELLOW}no${NC}"
fi

echo -n "  SSH session?       "
if [ -n "$SSH_TTY" ]; then
    echo -e "${GREEN}yes (pty: $SSH_TTY)${NC}"
else
    echo -e "${YELLOW}no${NC}"
fi

echo -n "  /dev/tty writable? "
if [ -w /dev/tty ] 2>/dev/null; then
    echo -e "${GREEN}yes${NC}"
else
    echo -e "${RED}no${NC}"
fi

echo -n "  tmux passthrough?  "
if command -v tmux >/dev/null 2>&1 && [ -n "$TMUX" ]; then
    if tmux show-options -g allow-passthrough 2>/dev/null | grep -q "on"; then
        echo -e "${GREEN}on${NC}"
    else
        echo -e "${RED}off${NC}"
    fi
else
    echo -e "${YELLOW}N/A (not in tmux)${NC}"
fi

# Detect which PTY the current pane uses
TMUX_PANE_TTY=""
if command -v tmux >/dev/null 2>&1 && [ -n "$TMUX" ]; then
    TMUX_PANE_TTY=$(tmux display-message -p '#{pane_tty}' 2>/dev/null || echo "")
    echo -n "  Tmux pane pty:     "
    if [ -n "$TMUX_PANE_TTY" ]; then
        echo -e "${GREEN}${TMUX_PANE_TTY}${NC}"
    else
        echo -e "${YELLOW}unknown${NC}"
    fi
fi

echo ""

# ── Test 1: Direct SSH pty (bypasses tmux) ──────────────────────────
section "Test 1: SSH_TTY direct write (bypasses tmux)"

if [ -n "$SSH_TTY" ] && [ -w "$SSH_TTY" ]; then
    # shellcheck disable=SC2059
    printf '\e]9;opencode: TEST 1 — Direct SSH pty (bypass tmux)\a' > "$SSH_TTY"
    echo -e "  ${GREEN}✓ Sent to $SSH_TTY${NC}"
else
    echo -e "  ${YELLOW}⊘ Skipped — no writable SSH_TTY${NC}"
fi

sleep 0.5

# ── Test 2: Tmux DCS passthrough wrapper ────────────────────────────
section "Test 2: Tmux DCS passthrough wrapper"

if [ -n "$TMUX" ]; then
    # Tmux DCS wrapper: \ePtmux;\e<osc-sequence>\e\\
    # This is the protocol tmux uses for passthrough (same as OSC 52 clipboard)
    printf '\ePtmux;\e\e]9;opencode: TEST 2 — Tmux DCS passthrough wrapper\a\e\\'
    echo -e "  ${GREEN}✓ Sent via tmux DCS wrapper${NC}"
else
    echo -e "  ${YELLOW}⊘ Skipped — not in tmux${NC}"
fi

sleep 0.5

# ── Test 3: Raw OSC 9 to stdout ─────────────────────────────────────
section "Test 3: Raw OSC 9 to stdout"

printf '\e]9;opencode: TEST 3 — Raw OSC 9 via stdout\a'
echo -e "  ${GREEN}✓ Sent via stdout${NC}"

sleep 0.5

# ── Test 4: Raw OSC 9 to stderr ─────────────────────────────────────
section "Test 4: Raw OSC 9 to stderr"

printf '\e]9;opencode: TEST 4 — Raw OSC 9 via stderr\a' >&2
echo -e "  ${GREEN}✓ Sent via stderr${NC}"

sleep 0.5

# ── Test 5: Raw OSC 9 to tmux pane pty ──────────────────────────────
if [ -n "$TMUX_PANE_TTY" ] && [ -w "$TMUX_PANE_TTY" ]; then
    section "Test 5: Raw OSC 9 to tmux pane pty ($TMUX_PANE_TTY)"
    printf '\e]9;opencode: TEST 5 — Direct to tmux pane pty\a' > "$TMUX_PANE_TTY"
    echo -e "  ${GREEN}✓ Sent to $TMUX_PANE_TTY${NC}"
fi

echo ""
echo -e "${BOLD}${CYAN}────────────────────────────────────────────────────────${NC}"
echo ""
echo -e "  ${BOLD}Which tests produced a notification on your desktop?${NC}"
echo ""
echo -e "  If ${GREEN}Test 1${NC} worked but others didn't:"
echo -e "    → tmux is consuming the escape sequences."
echo -e "    → The plugin is configured to use SSH_TTY for this case."
echo ""
echo -e "  If ${GREEN}Test 2${NC} (tmux DCS wrapper) worked:"
echo -e "    → The DCS passthrough protocol works correctly."
echo -e "    → The plugin's tmux fallback path will also work."
echo ""
echo -e "  If ${RED}no tests${NC} produced a notification:"
echo -e "    1. Check notification daemon on ${BOLD}local${NC} machine:"
echo -e "       notify-send 'test' 'hello'"
echo -e "    2. Check WezTerm supports OSC 9 (all modern versions do)"
echo -e "    3. Check if your desktop environment blocks WezTerm notifications"
echo ""
echo -e "  Debug: watch notification bus on ${BOLD}local${NC} machine:"
echo -e "       dbus-monitor interface=org.freedesktop.Notifications"
echo ""
echo -e "${BOLD}${CYAN}────────────────────────────────────────────────────────${NC}"
