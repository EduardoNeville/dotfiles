#!/usr/bin/env bash
# setup_network_manager.sh — make NetworkManager own the wired NIC, prefer it
# over wifi, and take wifi down while it is up.
#
# Why this is needed
#   The Debian installer writes a DHCP stanza for the ethernet device into
#   /etc/network/interfaces and NetworkManager.conf has [ifupdown]
#   managed=false, so NM never managed the wire. Observed consequences:
#     - ifupdown brought the cable up with route metric 1002 (1000+ifindex) while
#       wifi kept NM's 600, so which link won depended on activation order;
#     - ifupdown reacts to the *device* appearing, never to a *cable* being
#       plugged, so plugging in after boot is not an event for anybody;
#     - `nmcli device set <dev> managed yes` cannot override the plugin.
#
# Two failure modes found the hard way (2026-09-16), both handled below:
#   1. `ifdown` must run while the ifupdown stanza still exists — ifdown reads
#      the config to know how to deconfigure, so commenting the stanza out first
#      makes it a silent no-op (and leaves the address, its dhclient and the
#      ifupdown state file entry behind).
#   2. Even with ifupdown out of the way, a leftover address/route on the device
#      makes NetworkManager report "connected (externally)" and refuse to
#      autoconnect its own profile. It has to be flushed.
#
# What it does, in order (idempotent; timestamped backup of the interfaces file)
#   A. ethernet: ifdown while the stanza is still there → comment the stanza out
#      → flush any foreign configuration left on the device → restart
#      NetworkManager → `nmcli device connect` anything that did not come up on
#      its own. Result: "Wired connection 1", route-metric 100 against wifi's
#      600, carrier watched: cable in → wire, cable out → wifi.
#   C. install /etc/NetworkManager/dispatcher.d/90-prefer-wired: wifi down while
#      the wire is up, back up when it goes.
# Static stanzas abort the run and are reported: converting a fixed address into
# an NM profile is a decision, not a fix.
#
#   setup_network_manager.sh            — apply A + C
#   setup_network_manager.sh --dry-run  — print the planned actions; no sudo,
#                                         no changes
#
# It finishes by *checking* the outcome and printing PASS or FAIL — the first
# version printed "✓ released" unconditionally, which hid exactly the failure
# above.

set -u

IFACES="${IFACES:-/etc/network/interfaces}"
SELF_DIR="$(cd "$(dirname "$0")" && pwd)"
DISPATCHER_SRC="$SELF_DIR/networkmanager-90-prefer-wired.sh"
DISPATCHER_DST=/etc/NetworkManager/dispatcher.d/90-prefer-wired
DRY_RUN=0
[ "${1:-}" = "--dry-run" ] && DRY_RUN=1

say() { printf '%s\n' "$*"; }
# All state-changing calls go through these, so --dry-run can rehearse the whole
# script (with a stubbed PATH) without touching the machine.
do_sudo() { if [ "$DRY_RUN" = 1 ]; then say "  [dry-run] sudo $*"; else sudo "$@"; fi; }
do_cmd()  { if [ "$DRY_RUN" = 1 ]; then say "  [dry-run] $*"; else "$@"; fi; }

command -v nmcli >/dev/null 2>&1 || { say "NetworkManager not installed — skipping"; exit 0; }
[ -f "$IFACES" ] || { say "no $IFACES — nothing to do"; exit 0; }

dev_status() {  # dev_status <device> → nmcli's STATE field for it
    nmcli -t -f DEVICE,STATE device status 2>/dev/null \
        | awk -F: -v d="$1" '$1 == d { print $2; exit }'
}
eth_devs="$(nmcli -t -f DEVICE,TYPE device 2>/dev/null | awk -F: '$2 == "ethernet" { print $1 }')"

# ── static stanzas: not our business ─────────────────────────
static_devs="$(awk '/^[[:space:]]*iface[[:space:]]/ && $0 ~ /inet[[:space:]]+static/ { print $2 }' "$IFACES")"
if [ -n "$static_devs" ]; then
    say "  ! static stanza(s) for: $(echo "$static_devs" | tr '\n' ' ')"
    say "    leaving $IFACES untouched — move those to NetworkManager by hand, then re-run."
    exit 0
fi

handover="$(awk '/^[[:space:]]*iface[[:space:]]/ && $0 ~ /inet[[:space:]]+(dhcp|auto)/ && $2 != "lo" { print $2 }' "$IFACES")"
for d in $handover; do
    case " $eth_devs " in *" $d "*) ;; *) eth_devs="$eth_devs $d" ;; esac
done
eth_devs="$(printf '%s\n' $eth_devs)"
[ -n "$eth_devs" ] || { say "no ethernet device found — nothing to do"; exit 0; }
say "ethernet device(s): $(echo "$eth_devs" | tr '\n' ' ')"

# ── A1. release from ifupdown *before* editing the file ──────
for dev in $handover; do
    say "→ $dev: ifdown (stanza still present, so ifdown can act on it)"
    do_sudo ifdown --force "$dev"
    if grep -q "^$dev=" /run/network/ifstate 2>/dev/null; then
        say "  ! $dev is still listed in /run/network/ifstate"
    else
        say "  ✓ $dev not (or no longer) in ifupdown's state file"
    fi
done

# ── A2. comment the stanzas out ──────────────────────────────
if [ -n "$handover" ]; then
    printf '%s\n' "$handover" | awk '
        NR == FNR { wanted[$1] = 1; next }
        /^[[:space:]]*(auto|allow-hotplug|iface)[[:space:]]/ {
            dev = $2
            if (dev in wanted) {
                if (!(dev in seen)) {
                    print "# dotfiles: NetworkManager owns " dev \
                          " (profiles/desktop/scripts/setup_network_manager.sh)"
                    seen[dev] = 1
                }
                print "#" $0
                next
            }
        }
        { print }
    ' - "$IFACES" >/tmp/interfaces.new

    if [ "$DRY_RUN" = 1 ]; then
        say "→ would comment these lines in $IFACES:"
        diff "$IFACES" /tmp/interfaces.new | sed 's/^/    /' || true
        rm -f /tmp/interfaces.new
    else
        backup="$IFACES.bak-dotfiles-$(date +%Y%m%d_%H%M%S)"
        do_sudo cp -a "$IFACES" "$backup"
        do_sudo install -m 644 -o root -g root /tmp/interfaces.new "$IFACES"
        rm -f /tmp/interfaces.new
        say "  ✓ stanzas commented out (backup: $backup)"
    fi
else
    say "  ✓ no ifupdown DHCP stanza left to comment out"
fi

# ── A3. flush foreign configuration so NM will adopt the device ──
for dev in $eth_devs; do
    status="$(dev_status "$dev")"
    has_addr=0
    ip -4 addr show dev "$dev" 2>/dev/null | grep -q 'inet ' && has_addr=1
    has_route=0
    ip route show default 2>/dev/null | grep -q " dev $dev " && has_route=1

    case "$status" in
        *externally*)
            say "→ $dev is 'connected (externally)' — flushing so NM can take it over"
            do_sudo ip addr flush dev "$dev"
            do_sudo ip route flush dev "$dev"
            ;;
        unmanaged)
            say "  ! $dev is unmanaged by NetworkManager"
            if [ "$has_addr" = 1 ] || [ "$has_route" = 1 ]; then
                say "    clearing leftover address/route anyway"
                do_sudo ip addr flush dev "$dev"
                do_sudo ip route flush dev "$dev"
            fi
            ;;
        disconnected)
            if [ "$has_route" = 1 ]; then
                say "→ $dev is disconnected but still holds a default route — clearing"
                do_sudo ip route flush dev "$dev"
                [ "$has_addr" = 1 ] && do_sudo ip addr flush dev "$dev"
            fi
            ;;
        *)
            [ "$has_route" = 1 ] && say "  (note: $dev state '$status' with a default route)"
            ;;
    esac
done

# ── A4. restart NM, then connect explicitly if needed ────────
do_sudo systemctl restart NetworkManager
if [ "$DRY_RUN" = 0 ]; then sleep 3; fi
for dev in $eth_devs; do
    status="$(dev_status "$dev")"
    case "$status" in
        connected) say "  ✓ $dev connected by NetworkManager" ;;
        *)
            say "→ $dev is '$status' — connecting it explicitly"
            do_sudo nmcli --wait 10 device connect "$dev"
            ;;
    esac
done

# ── C. wifi off while the wire is up ─────────────────────────
if [ -r "$DISPATCHER_SRC" ]; then
    do_sudo install -m 755 -o root -g root "$DISPATCHER_SRC" "$DISPATCHER_DST"
    say "  ✓ $DISPATCHER_DST installed (wifi down while wired, back when unplugged)"
    say "    trace it with: journalctl -t prefer-wired -f"
else
    say "  ! $DISPATCHER_SRC missing — dispatcher not installed"
fi

if [ "$DRY_RUN" = 1 ]; then
    say ""
    say "dry run: nothing changed."
    exit 0
fi

# ── verify honestly ──────────────────────────────────────────
say ""
say "=== result ==="
fail=0
for dev in $eth_devs; do
    line="$(nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device status 2>/dev/null | awk -F: -v d="$dev" '$1 == d')"
    say "  $line"
    case "$(dev_status "$dev")" in
        connected) ;;
        *) fail=1 ;;
    esac
done

say "--- default routes ---"
ip route show default | sed 's/^/  /'
say "--- effective path ---"
ip route get 1.1.1.1 2>/dev/null | head -1 | sed 's/^/  /'
say "--- wifi state (should be disconnected while the cable is in) ---"
nmcli -t -f DEVICE,TYPE,STATE device status 2>/dev/null | awk -F: '$2 == "wifi" { print "  " $1 ": " $3 }'
say ""
if [ "$fail" = 0 ]; then
    say "PASS: the ethernet device is connected under NetworkManager."
    say "Unplug/replug the cable to see the hand-off; watch journalctl -t prefer-wired -f."
else
    say "FAIL: an ethernet device is not connected under NetworkManager."
    say "Diagnose with:"
    say "  nmcli device show <dev> | head -20"
    say "  journalctl -u NetworkManager --since -10min | grep -iE 'ifupdown|unmanaged|<dev>'"
    say "  cat /run/network/ifstate"
fi
