#!/bin/bash
# One-time setup for theme propagation remote hosts.
#
#   - creates ~/.config/theme/remote-hosts (default: deep-blue) if missing
#   - prints the one-time per-host setup checklist
#   - validates connectivity to every configured host (tailscale ssh first,
#     plain ssh fallback) and attempts to trust the host key automatically
#     via ssh-keyscan when the probe fails
#
# Per-host setup checklist (also printed here):
#   1. sudo tailscale up --ssh          # enable Tailscale SSH on the host
#   2. ssh-keyscan <host> >> ~/.ssh/known_hosts
#                                       # trust the host key (auto-attempted
#                                       # by this script when a probe fails)
#   3. ssh-copy-id <user>@<host>        # allow the plain-SSH key fallback
#
# Exit status: 0 when every configured host is reachable, 1 otherwise.

set -u

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/theme"
REMOTE_HOSTS="$CONFIG_DIR/remote-hosts"

mkdir -p "$CONFIG_DIR"

# ── 1. Ensure remote-hosts exists ─────────────────────────────
if [ ! -f "$REMOTE_HOSTS" ]; then
    cat > "$REMOTE_HOSTS" <<'EOF'
# One hostname per line. Lines starting with '#' are ignored.
# See configs/theme/remote-hosts.example in the dotfiles repo for docs.
deep-blue
EOF
    echo "Created $REMOTE_HOSTS with default host 'deep-blue'."
else
    echo "Using existing $REMOTE_HOSTS."
fi

echo
echo "=== One-time setup checklist (per host) ==="
echo "  On each host below, run:   sudo tailscale up --ssh"
echo "  From this machine, run:    ssh-keyscan <host> >> ~/.ssh/known_hosts"
echo "                              ssh-copy-id <user>@<host>"
echo

# ── Helpers ──────────────────────────────────────────────────

# Probe a single host; prints what happened. Returns 0 when reachable.
_probe() {
    local host="$1"
    local out=""

    # Primary: Tailscale SSH
    if command -v tailscale &>/dev/null; then
        out=$(timeout 8 tailscale ssh "$host" "echo ts-ok" 2>&1)
        if [ $? -eq 0 ]; then
            echo "  tailscale ssh: OK"
            return 0
        fi
        echo "  tailscale ssh: failed ($(printf '%s\n' "$out" | tail -1 | tr -d '\r'))"
    fi

    # Fallback: plain SSH (accept-new trusts a new host key automatically)
    out=$(timeout 8 ssh -o ConnectTimeout=5 -o BatchMode=yes \
        -o StrictHostKeyChecking=accept-new "$host" "echo ssh-ok" 2>&1)
    if [ $? -eq 0 ]; then
        echo "  plain ssh: OK"
        return 0
    fi
    echo "  plain ssh: failed ($(printf '%s\n' "$out" | tail -1 | tr -d '\r'))"
    return 1
}

# Trust the host key of <host>. Tries the name first, then falls back to the
# Tailscale IP when the name does not resolve to a reachable address
# (e.g. a stale /etc/hosts entry). Returns 0 when keys were added.
_keyscan() {
    local host="$1"
    local ip="" out=""

    out=$(timeout 10 ssh-keyscan -T 5 "$host" 2>/dev/null)
    if [ -n "$out" ]; then
        mkdir -p "$HOME/.ssh"
        echo "$out" >> "$HOME/.ssh/known_hosts"
        echo "  added host key(s) for '$host' to ~/.ssh/known_hosts"
        return 0
    fi
    echo "  ssh-keyscan '$host' produced nothing (name may not resolve to a reachable address)"

    if command -v tailscale &>/dev/null; then
        ip=$(timeout 5 tailscale ip -4 "$host" 2>/dev/null)
        if [ -n "$ip" ]; then
            out=$(timeout 10 ssh-keyscan -T 5 "$ip" 2>/dev/null)
            if [ -n "$out" ]; then
                mkdir -p "$HOME/.ssh"
                echo "$out" >> "$HOME/.ssh/known_hosts"
                echo "  added host key(s) for '$ip' (tailscale IP of '$host') to ~/.ssh/known_hosts"
                return 0
            fi
        fi
    fi
    echo "  could not obtain a host key for '$host' (is sshd reachable?)"
    return 1
}

# ── 2. Validate connectivity ──────────────────────────────────
echo "=== Validating connectivity ==="
FAILED=0
while IFS= read -r host || [ -n "$host" ]; do
    case "$host" in
        ''|\#*) continue ;;
    esac

    echo
    echo "--- $host ---"
    if _probe "$host"; then
        echo "  OK: reachable."
        continue
    fi

    echo "  -> attempting host-key trust via ssh-keyscan ..."
    _keyscan "$host" || true
    if _probe "$host"; then
        echo "  OK after ssh-keyscan: reachable."
        continue
    fi

    echo "  FAILED: '$host' is not reachable."
    echo "  Fixes to apply:"
    echo "    - enable Tailscale SSH on the host:      sudo tailscale up --ssh"
    echo "    - authorize plain-SSH key auth:          ssh-copy-id <user>@$host"
    echo "    - check DNS resolution for '$host' (a stale /etc/hosts entry"
    echo "      pointing at an unreachable IP is a common cause)"
    FAILED=1
done < "$REMOTE_HOSTS"

echo
if [ "$FAILED" = "0" ]; then
    echo "All configured hosts are reachable."
    exit 0
else
    echo "Some hosts failed connectivity checks — see above."
    exit 1
fi
