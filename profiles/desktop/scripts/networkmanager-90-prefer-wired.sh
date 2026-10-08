#!/bin/sh
# networkmanager-90-prefer-wired.sh — installed as
# /etc/NetworkManager/dispatcher.d/90-prefer-wired by
# profiles/desktop/scripts/setup_network_manager.sh (option C).
#
# NetworkManager runs dispatcher scripts for every interface event: $1 is the
# interface, $2 is the action. While an *ethernet* interface is up, take wifi
# down; when the cable goes, bring it back. That gives one active link instead
# of "wifi connected but unused as fallback".
#
# Interface types are looked up rather than hardcoding device names, so this
# works on any machine. Manual `nmcli device disconnect` is deliberately used
# (not `radio wifi off`): it is runtime-only, so a boot without a cable still
# gets wifi, and NM reconnects on demand.
#
# nmcli calls use --wait so the script stays well inside NetworkManager's
# 10-second dispatcher timeout.

set -u

IFACE="${1:-}"
ACTION="${2:-}"
[ -n "$IFACE" ] && [ -n "$ACTION" ] || exit 0

command -v nmcli >/dev/null 2>&1 || exit 0

# Only act on ethernet up/down; ignore everything else.
type="$(nmcli -t -f DEVICE,TYPE device 2>/dev/null | awk -F: -v d="$IFACE" '$1 == d { print $2; exit }')"
[ "$type" = "ethernet" ] || exit 0

wifi_dev="$(nmcli -t -f DEVICE,TYPE device 2>/dev/null | awk -F: '$2 == "wifi" { print $1; exit }')"
[ -n "$wifi_dev" ] || exit 0

wifi_state="$(nmcli -t -f DEVICE,STATE device 2>/dev/null | awk -F: -v d="$wifi_dev" '$1 == d { print $2; exit }')"

case "$ACTION" in
    up)
        if [ "$wifi_state" = "connected" ]; then
            nmcli --wait 5 device disconnect "$wifi_dev" >/dev/null 2>&1 || true
            logger -t prefer-wired "ethernet $IFACE up — wifi $wifi_dev disconnected"
        fi
        ;;
    down)
        if [ "$wifi_state" != "connected" ]; then
            nmcli --wait 5 device connect "$wifi_dev" >/dev/null 2>&1 || true
            logger -t prefer-wired "ethernet $IFACE down — wifi $wifi_dev reconnected"
        fi
        ;;
esac
