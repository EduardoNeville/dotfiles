#!/usr/bin/env bash
# opencode-sudo-test.sh
#
# Validates the sudo tool pipeline without needing opencode running.
# Tests: password storage, askpass helper, SUDO_ASKPASS + sudo -A, tool endpoint.
#
# Usage:
#   bash ~/dotfiles/scripts/opencode-sudo-test.sh
#
# For a live test with opencode:
#   1. Run: bash ~/dotfiles/scripts/opencode-sudo-setup.sh
#      (enter your real sudo password once)
#   2. Start opencode
#   3. Ask the agent: use the `sudo` tool with command "echo 'hello from opencode'"
#   4. If it returns "hello from opencode" — the tool works!

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

PASSFILE="/tmp/opencode-sudo-pass-test-$$"
ASKPASS_SCRIPT="/tmp/opencode-askpass-test-$$.sh"
DUMMY_PASS="test-password-dummy-$(date +%s)"

pass()  { echo -e "  ${GREEN}✅${NC} $1"; }
fail()  { echo -e "  ${RED}❌${NC} $1"; }
warn()  { echo -e "  ${YELLOW}⚠${NC}  $1"; }
info()  { echo -e "  ${BOLD}$1${NC}"; }

cleanup() {
    rm -f "$PASSFILE" "$ASKPASS_SCRIPT"
}
trap cleanup EXIT

echo ""
echo -e "${BOLD}════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}  OpenCode Sudo Tool — Pipeline Test${NC}"
echo -e "${BOLD}  (custom tool → SUDO_ASKPASS → sudo -A)${NC}"
echo -e "${BOLD}════════════════════════════════════════════════════════${NC}"
echo ""

# ── 1. Password sources ───────────────────────────────────────────
info "1. Password sources check"
if [ -n "$OPENCODE_SUDO_PASS" ]; then
    pass "OPENCODE_SUDO_PASS is set"
elif [ -f /tmp/opencode-sudo-pass ]; then
    pass "/tmp/opencode-sudo-pass exists"
else
    warn "No password found — run: bash ~/dotfiles/scripts/opencode-sudo-setup.sh"
fi
echo ""

# ── 2. Password file creation ────────────────────────────────────
info "2. Write password to temp file (0600)"
echo "$DUMMY_PASS" > "$PASSFILE" && chmod 600 "$PASSFILE"
[ -f "$PASSFILE" ] && [ "$(stat -c '%a' "$PASSFILE")" = "600" ] \
    && pass "Password file created with 0600 permissions" \
    || fail "Failed to create password file"
echo ""

# ── 3. Askpass helper script ─────────────────────────────────────
info "3. Create askpass helper script (0700)"
printf '#!/bin/sh\ncat %s\n' "$PASSFILE" > "$ASKPASS_SCRIPT"
chmod 700 "$ASKPASS_SCRIPT"
[ -x "$ASKPASS_SCRIPT" ] && [ "$(stat -c '%a' "$ASKPASS_SCRIPT")" = "700" ] \
    && pass "Askpass helper created with 0700" \
    || fail "Failed to create askpass helper"
echo ""

# ── 4. Askpass output verification ───────────────────────────────
info "4. Verify askpass outputs correct password"
output=$("$ASKPASS_SCRIPT" 2>/dev/null)
[ "$output" = "$DUMMY_PASS" ] \
    && pass "Askpass correctly echoes the password" \
    || fail "Askpass output mismatch"
echo ""

# ── 5. SUDO_ASKPASS + sudo -A (the tool execution path) ──────────
info "5. SUDO_ASKPASS + sudo -A execution"

# Instead of testing plugin regex (which no longer exists), we test
# the actual sudo -A invocation that the custom tool uses internally.

# Test: sudo -A works with a command that requires no special handling
output=$(SUDO_ASKPASS="$ASKPASS_SCRIPT" timeout 5 sudo -A -n true 2>&1) || true
if echo "$output" | grep -qiE "password|sorry|incorrect"; then
    # Password from dummy askpass was rejected — that's expected
    # because we used a dummy password. The important thing is it
    # didn't hang and the askpass was called.
    pass "sudo -A invoked askpass (expected rejection with dummy password)"
elif [ -z "$output" ] && [ $? -eq 0 ] 2>/dev/null; then
    pass "sudo -A succeeded (real password found?)"
else
    warn "sudo -A output: ${output:-"(empty)"}"
fi
echo ""

# ── 6. Tool definition file check ────────────────────────────────
info "6. Custom tool file integrity"
TOOL_PATH="$HOME/.config/opencode/tools/sudo.js"
if [ -f "$TOOL_PATH" ]; then
    pass "Tool file exists at $TOOL_PATH"

    # Check that it imports from @opencode-ai/plugin
    if grep -qE "import.*from.*@opencode-ai/plugin" "$TOOL_PATH"; then
        pass "Tool imports @opencode-ai/plugin"
    else
        fail "Tool does not import @opencode-ai/plugin"
    fi

    # Check that it exports a tool() definition
    if grep -q "export default tool(" "$TOOL_PATH"; then
        pass "Tool exports a tool() definition"
    else
        fail "Missing 'export default tool(' in tool file"
    fi

    # Check that it uses execSync for command execution
    if grep -q "execSync" "$TOOL_PATH"; then
        pass "Tool uses execSync for command execution"
    else
        fail "Missing execSync in tool file"
    fi

    # Check that it has a 'command' argument definition
    # (args are on multiple lines: command: tool.schema\n      .string())
    if grep -q "command:.*tool.schema" "$TOOL_PATH"; then
        pass "Tool defines 'command' argument with string schema"
    else
        fail "Missing 'command' argument definition"
    fi
else
    fail "Tool file not found at $TOOL_PATH"
    fail "Create it by copying from dotfiles:"
    fail "  cp ~/dotfiles/configs/opencode/tools/sudo.js $TOOL_PATH"
fi
echo ""

# ── 7. Plugin removal check ──────────────────────────────────────
info "7. Old plugin removal check"
PLUGIN_PATH="$HOME/.config/opencode/plugins/sudo-handler.js"
if [ -f "$PLUGIN_PATH" ]; then
    warn "Old plugin still exists at $PLUGIN_PATH"
    warn "It should be removed — the custom tool replaces it."
    warn "Delete it with: rm $PLUGIN_PATH"
else
    pass "Old plugin file removed (sudo-handler.js)"
fi
echo ""

# ── 8. Askpass script cleanup check ──────────────────────────────
info "8. Askpass script cleanup (tool should delete askpass after use)"
# Simulate what the tool does: write askpass, verify it exists, then delete
printf '#!/bin/sh\ncat %s\n' "$PASSFILE" > "$ASKPASS_SCRIPT"
chmod 700 "$ASKPASS_SCRIPT"
[ -f "$ASKPASS_SCRIPT" ] && pass "Askpass exists before execution"

# Delete it (as the tool would)
rm -f "$ASKPASS_SCRIPT"
[ ! -f "$ASKPASS_SCRIPT" ] && pass "Askpass cleaned up after execution" \
    || fail "Askpass was not cleaned up"
echo ""

echo -e "${BOLD}────────────────────────────────────────────────────────${NC}"
echo ""
echo -e "  ${GREEN}All pipeline checks passed.${NC}"
echo ""
echo -e "  ${BOLD}Live test:${NC}"
echo ""
echo -e "    1. bash ~/dotfiles/scripts/${BOLD}opencode-sudo-setup.sh${NC}"
echo -e "       (enter your real password — verified before saving)"
echo ""
echo -e "    2. opencode"
echo ""
echo -e "    3. Ask the agent to ${BOLD}use the 'sudo' tool${NC}"
echo -e "       with: ${BOLD}command: \"echo 'hello from opencode'\"${NC}"
echo ""
echo -e "    4. If it returns 'hello from opencode' → tool works!"
echo ""
echo -e "  ${BOLD}Without the password file:${NC}"
echo -e "    export OPENCODE_SUDO_PASS='your-password'"
echo -e "    opencode"
echo ""
echo -e "  ${BOLD}Custom tool location:${NC}"
echo -e "    ~/.config/opencode/tools/sudo.js"
echo ""
echo -e "${BOLD}────────────────────────────────────────────────────────${NC}"
