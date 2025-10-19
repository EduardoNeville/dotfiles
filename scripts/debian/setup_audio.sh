#!/usr/bin/env bash
# Author: Eduardo Neville <eduadoneville82@gmail.com>
# Description: Setup PipeWire audio system on Debian

set -e

_process() { echo "$(tput setaf 6)→ $1...$(tput sgr0)"; }
_success() { echo "$(tput setaf 2)✓ Success:$(tput sgr0) $1"; }
_error() { echo "$(tput setaf 1)✗ Error:$(tput sgr0) $1"; }

check_pulseaudio() {
    _process "Checking for existing PulseAudio installation"

    if systemctl --user is-active --quiet pulseaudio.service 2>/dev/null; then
        _process "PulseAudio is running. Stopping it..."
        systemctl --user stop pulseaudio.service
        systemctl --user disable pulseaudio.service
        systemctl --user mask pulseaudio.service
        _success "PulseAudio disabled"
    fi

    if dpkg -l | grep -q "^ii  pulseaudio "; then
        read -p "Remove PulseAudio? (recommended) (y/n): " remove_pulse
        if [[ "$remove_pulse" =~ ^[Yy]$ ]]; then
            sudo apt remove -y pulseaudio
            _success "PulseAudio removed"
        fi
    fi
}

install_pipewire() {
    _process "Installing PipeWire and components"

    local packages=(
        "pipewire"
        "pipewire-audio-client-libraries"
        "pipewire-alsa"
        "pipewire-pulse"
        "wireplumber"
        "pavucontrol"
        "alsa-utils"
    )

    sudo apt update
    sudo apt install -y "${packages[@]}"

    _success "PipeWire packages installed"
}

install_bluetooth_audio() {
    _process "Installing Bluetooth audio support"

    local bt_packages=(
        "bluetooth"
        "bluez"
        "bluez-tools"
        "blueman"
        "libspa-0.2-bluetooth"
    )

    sudo apt install -y "${bt_packages[@]}"

    _success "Bluetooth audio support installed"
}

enable_pipewire() {
    _process "Enabling PipeWire services"

    # Enable and start PipeWire
    systemctl --user --now enable pipewire.service
    systemctl --user --now enable pipewire-pulse.service
    systemctl --user --now enable wireplumber.service

    # Wait a moment for services to start
    sleep 2

    _success "PipeWire services enabled and started"
}

configure_pipewire() {
    _process "Configuring PipeWire"

    # Create user config directory
    mkdir -p "${HOME}/.config/pipewire"

    # Copy default configs if they don't exist
    if [ ! -f "${HOME}/.config/pipewire/pipewire.conf" ]; then
        [ -f "/usr/share/pipewire/pipewire.conf" ] && \
            cp /usr/share/pipewire/pipewire.conf "${HOME}/.config/pipewire/"
    fi

    if [ ! -f "${HOME}/.config/pipewire/pipewire-pulse.conf" ]; then
        [ -f "/usr/share/pipewire/pipewire-pulse.conf" ] && \
            cp /usr/share/pipewire/pipewire-pulse.conf "${HOME}/.config/pipewire/"
    fi

    _success "PipeWire configuration created"
}

setup_bluetooth() {
    _process "Enabling Bluetooth service"

    sudo systemctl enable bluetooth.service
    sudo systemctl start bluetooth.service

    # Add user to bluetooth group
    sudo usermod -aG bluetooth ${USER}

    _success "Bluetooth service enabled"
}

test_audio() {
    _process "Testing audio setup"

    echo ""
    echo "===== Audio System Status ====="

    # Check PipeWire status
    if systemctl --user is-active --quiet pipewire.service; then
        echo "✓ PipeWire: Running"
    else
        echo "✗ PipeWire: Not running"
    fi

    if systemctl --user is-active --quiet pipewire-pulse.service; then
        echo "✓ PipeWire Pulse: Running"
    else
        echo "✗ PipeWire Pulse: Not running"
    fi

    if systemctl --user is-active --quiet wireplumber.service; then
        echo "✓ WirePlumber: Running"
    else
        echo "✗ WirePlumber: Not running"
    fi

    # Check Bluetooth
    if systemctl is-active --quiet bluetooth.service; then
        echo "✓ Bluetooth: Running"
    else
        echo "✗ Bluetooth: Not running"
    fi

    echo ""

    # List audio devices
    if command -v pactl >/dev/null 2>&1; then
        echo "Audio sinks (output devices):"
        pactl list short sinks
        echo ""
        echo "Audio sources (input devices):"
        pactl list short sources
    fi

    echo "==============================="
    echo ""
}

main() {
    _process "Setting up PipeWire audio system"

    check_pulseaudio
    install_pipewire
    install_bluetooth_audio
    configure_pipewire
    enable_pipewire
    setup_bluetooth

    test_audio

    _success "Audio system setup complete"

    echo ""
    echo "Audio setup complete!"
    echo ""
    echo "Notes:"
    echo "  - Use 'pavucontrol' to adjust audio settings"
    echo "  - Use 'blueman-manager' to manage Bluetooth devices"
    echo "  - Restart your session for all changes to take effect"
    echo "  - To connect Bluetooth audio: blueman-manager -> Pair device -> Set as audio output"
    echo ""
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
