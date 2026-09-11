#!/usr/bin/env bash
# scripts/macos/configure_system.sh — macOS adapter (brew).
# Taps + formulae are handled by install.sh; here: casks, links, default shell.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/os.sh"
source "${SCRIPT_DIR}/../lib/link.sh"

main() {
    _process "Configuring system (macOS)"

    if [ -f "${DOTFILES_DIR}/opt/casks.txt" ]; then
        _process "Installing casks"
        while read -r cask; do
            [ -n "$cask" ] && case "$cask" in \#*) ;; *) brew install --cask "$cask" ;; esac
        done <"${DOTFILES_DIR}/opt/casks.txt"
    fi

    link_dotfiles
    setup_zsh_as_default || true

    _success "System configuration complete (macOS)"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi