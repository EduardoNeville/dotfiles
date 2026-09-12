#!/bin/bash
# Tmux SSH Session Manager
# Quick launcher for SSH sessions within tmux

set -e

# Color codes
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if we're in tmux
if [ -z "$TMUX" ]; then
    echo -e "${YELLOW}Not in a tmux session. Starting tmux first...${NC}"
    tmux new-session -d -s ssh-manager 2>/dev/null || true
    tmux attach -t ssh-manager
    exit 0
fi

# Function to create SSH window
create_ssh_window() {
    local host="$1"
    local session_name="$(echo $host | cut -d'.' -f1 | cut -d'@' -f2)"
    
    # Check if window already exists
    if tmux list-windows -F "#W" | grep -q "^${session_name}$"; then
        tmux select-window -t "${session_name}"
        echo -e "${GREEN}Switched to existing window: ${session_name}${NC}"
    else
        tmux new-window -n "${session_name}" "ssh ${host}"
        echo -e "${GREEN}Created new SSH session to: ${host}${NC}"
    fi
}

# Menu
echo -e "${BLUE}=== Tmux SSH Manager ===${NC}"
echo ""
echo "1) SSH to custom host"
echo "2) Quick connect (type hostname)"
echo "3) Split current window and SSH"
echo "4) List active SSH sessions"
echo "5) Exit"
echo ""
read -p "Select option [1-5]: " choice

case $choice in
    1)
        read -p "Enter hostname (e.g., user@server.tailnet.ts.net): " host
        create_ssh_window "$host"
        ;;
    2)
        read -p "Hostname: " host
        # Auto-add tailscale domain if not present
        if [[ ! "$host" =~ \. ]]; then
            host="${host}.tailnet.ts.net"
        fi
        create_ssh_window "$host"
        ;;
    3)
        read -p "Enter hostname for split pane: " host
        tmux split-window -h "ssh ${host}"
        ;;
    4)
        echo -e "${BLUE}Active windows:${NC}"
        tmux list-windows -F "#I: #W #{?window_active,(active),}"
        ;;
    5)
        exit 0
        ;;
    *)
        echo "Invalid option"
        exit 1
        ;;
esac
