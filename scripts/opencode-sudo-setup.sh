#!/usr/bin/env bash
# opencode-sudo-setup.sh
#
# Securely prompts for your sudo password and stores it in a temp file
# that the opencode sudo-handler plugin reads at runtime.
#
# Usage:
#   bash ~/dotfiles/scripts/opencode-sudo-setup.sh
#   opencode   # password is ready — sudo commands will authenticate
#
# The password is stored in /tmp/opencode-sudo-pass (tmpfs) with 0600
# permissions. It persists until reboot or manual deletion.
#
# To clear: rm /tmp/opencode-sudo-pass
#
# Alternative (no file on disk):
#   export OPENCODE_SUDO_PASS='your-password'
#   opencode

set -e

BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

PASSFILE="/tmp/opencode-sudo-pass"

# Check if password already exists
if [ -f "$PASSFILE" ]; then
    echo -e "${YELLOW}A saved sudo password already exists.${NC}"
    read -r -p "Overwrite? (y/N): " overwrite
    if [[ ! "$overwrite" =~ ^[Yy]$ ]]; then
        echo -e "${GREEN}Keeping existing password.${NC}"
        echo "Run: rm $PASSFILE  to clear it."
        exit 0
    fi
fi

# Prompt for password (input hidden)
echo ""
read -r -s -p "Enter your sudo password: " password
echo ""

if [ -z "$password" ]; then
    echo -e "${RED}No password entered. Aborting.${NC}"
    exit 1
fi

# Verify the password works
echo -n "Verifying..."
if echo "$password" | sudo -S true 2>/dev/null; then
    echo -e " ${GREEN}correct${NC}"
else
    echo -e " ${RED}incorrect${NC}"
    echo ""
    echo "The password was rejected by sudo."
    echo "It has NOT been saved. Please try again."
    exit 1
fi

# Write to temp file with restricted permissions
printf '%s' "$password" > "$PASSFILE"
chmod 600 "$PASSFILE"

echo ""
echo -e "${GREEN}${BOLD}✓ Sudo password saved to $PASSFILE${NC}"
echo "  Permissions: 0600 (readable only by you)"
echo "  Storage:     /tmp (tmpfs — cleared on reboot)"
echo ""
echo "  To use:      start opencode normally"
echo "  To clear:    rm $PASSFILE"
echo ""
