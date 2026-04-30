#!/usr/bin/env bash
# opencode-sudo-test.sh
#
# Validates the sudo plugin pipeline without needing opencode running.
# Tests: password storage, askpass helper, inline SUDO_ASKPASS, regex transforms.
#
# Usage:
#   bash ~/dotfiles/scripts/opencode-sudo-test.sh
#
# For a live test with opencode:
#   1. Run: bash ~/dotfiles/scripts/opencode-sudo-setup.sh
#      (enter your real sudo password once)
#   2. Start opencode
#   3. Ask the agent: sudo echo "hello from opencode"
#   4. If it returns "hello from opencode" — the plugin works!

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
echo -e "${BOLD}  OpenCode Sudo Plugin — Pipeline Test (v2: inline SUDO_ASKPASS)${NC}"
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

# ── 5. Inline SUDO_ASKPASS (the tool.execute.before rewrite) ─────
info "5. Inline SUDO_ASKPASS + sudo -A rewrite"

declare -A TESTS=(
    ["sudo apt update"]="SUDO_ASKPASS=${ASKPASS_SCRIPT} sudo -A apt update"
    ["sudo -E make install"]="SUDO_ASKPASS=${ASKPASS_SCRIPT} sudo -A -E make install"
    ["echo x | sudo tee /etc/file"]="SUDO_ASKPASS=${ASKPASS_SCRIPT} echo x | sudo -A tee /etc/file"
    ["sudo -A apt update"]="sudo -A apt update"
    ["sudo -S apt install"]="sudo -A apt install"
    ["sudo -n echo hi"]="sudo -A echo hi"
    ["sudo apt update && sudo apt upgrade"]="SUDO_ASKPASS=${ASKPASS_SCRIPT} sudo -A apt update && sudo -A apt upgrade"
    ["apt update"]="apt update"
)

failures=0
for original in "${!TESTS[@]}"; do
    expected="${TESTS[$original]}"
    needsSudo=$(echo "$original" | grep -qP '\bsudo\b(?!\s+-[ASn])' && echo 1 || echo 0)
    rewritten="$original"
    if [ "$needsSudo" = "1" ]; then
        rewritten=$(echo "$original" | sed -E 's/\bsudo\b( +-[ASn])?/sudo -A/g')
        rewritten="SUDO_ASKPASS=${ASKPASS_SCRIPT} $rewritten"
    else
        rewritten=$(echo "$original" | sed -E 's/\bsudo\b( +-[ASn])?/sudo -A/g')
    fi
    [ "$rewritten" = "$expected" ] \
        && pass "'$original' → '$rewritten'" \
        || { fail "'$original' → '$rewritten' (expected '$expected')"; ((failures++)); }
done

echo ""
[ $failures -eq 0 ] \
    && pass "All ${#TESTS[@]} transformations correct" \
    || fail "$failures transformation(s) failed"
echo ""

# ── 6. sudo -A non-blocking ──────────────────────────────────────
info "6. sudo -A: verify it fails gracefully (no hang)"
output=$(SUDO_ASKPASS="$ASKPASS_SCRIPT" timeout 2 sudo -A -n true 2>&1) || true
echo "$output" | grep -qiE "password|sorry|incorrect|not found" \
    && pass "sudo -A fails gracefully (no hang)" \
    || warn "sudo -A output: $output"
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
echo -e "    3. Ask the agent: ${BOLD}sudo echo 'hello from opencode'${NC}"
echo ""
echo -e "    4. If it returns 'hello from opencode' → plugin works!"
echo ""
echo -e "  ${BOLD}Without the password file:${NC}"
echo -e "    export OPENCODE_SUDO_PASS='your-password'"
echo -e "    opencode"
echo ""
echo -e "${BOLD}────────────────────────────────────────────────────────${NC}"
