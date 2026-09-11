#!/usr/bin/env bash
# Author: Eduardo Neville <eduadoneville82@gmail.com>
# Description: Install NVM and Node.js

set -e

_process() { echo "$(tput setaf 6)→ $1...$(tput sgr0)"; }
_success() { echo "$(tput setaf 2)✓ Success:$(tput sgr0) $1"; }
_error() { echo "$(tput setaf 1)✗ Error:$(tput sgr0) $1"; }

install_wezterm() {
    _process "Installing Wezterm"

    curl -fsSL https://apt.fury.io/wez/gpg.key | sudo gpg --yes --dearmor -o /usr/share/keyrings/wezterm-fury.gpg
    echo 'deb [signed-by=/usr/share/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *' | sudo tee /etc/apt/sources.list.d/wezterm.list
    sudo chmod 644 /usr/share/keyrings/wezterm-fury.gpg
    sudo apt update
    sudo apt install -y wezterm
}

main() {
    _process "Wezterm Installation"

    install_wezterm

    _success "Wezterm Installed"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
