#!/usr/bin/env bash
# setup_audio.sh — desktop audio/bt/wifi service wiring (packages are DECLARED
# in profiles/desktop/packages.apt — this script only enables/verifies).
# Trixie ships everything current (pipewire 1.4, bluez 5.82) — no source builds.

set -e

_process() { echo "$(tput setaf 6)→ $1...$(tput sgr0)"; }
_success() { echo "$(tput setaf 2)✓ Success:$(tput sgr0) $1"; }
_error() { echo "$(tput setaf 1)✗ Error:$(tput sgr0) $1"; }

enable_pipewire() {
    _process "Enabling PipeWire user services (startx session has no login manager)"
    systemctl --user --now enable pipewire.service 2>/dev/null || true
    systemctl --user --now enable pipewire-pulse.service 2>/dev/null || true
    systemctl --user --now enable wireplumber.service 2>/dev/null || true
    _success "PipeWire services enabled"
}

setup_bluetooth() {
    _process "Enabling Bluetooth (system service)"
    sudo systemctl enable bluetooth.service 2>/dev/null || true
    sudo systemctl start bluetooth.service 2>/dev/null || true
    sudo usermod -aG bluetooth "${USER}" 2>/dev/null || true
    command -v rfkill >/dev/null 2>&1 && { rfkill unblock bluetooth 2>/dev/null || true; }
    _success "Bluetooth service enabled"
}

setup_wifi() {
    _process "Enabling NetworkManager (system service)"
    sudo systemctl enable NetworkManager.service 2>/dev/null || true
    sudo systemctl start NetworkManager.service 2>/dev/null || true
    command -v rfkill >/dev/null 2>&1 && { rfkill unblock wifi 2>/dev/null || true; }
    _success "NetworkManager enabled"
}

test_audio() {
    _process "Verifying audio/bluetooth/wifi"
    echo "  $(systemctl --user is-active pipewire.service 2>/dev/null || echo 'pipewire: n/a')"
    echo "  $(systemctl --user is-active pipewire-pulse.service 2>/dev/null || echo 'pulse: n/a')"
    echo "  $(systemctl --user is-active wireplumber.service 2>/dev/null || echo 'wireplumber: n/a')"
    echo "  bluetooth: $(systemctl is-active bluetooth.service 2>/dev/null || echo n/a)"
    command -v nmcli >/dev/null 2>&1 && nmcli device status 2>/dev/null | sed 's/^/  /'
    _success "Status printed above (wifi needing an SSID: nmtui)"
}

main() {
    enable_pipewire
    setup_bluetooth
    setup_wifi
    test_audio
    _success "Desktop services setup complete"
    echo ""
    echo "First-run wifi: nmtui (no tray; nm-applet needs one). Bluetooth: blueman-manager."
    echo "Bluetooth devices: blueman-manager. Volume: pavucontrol."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi