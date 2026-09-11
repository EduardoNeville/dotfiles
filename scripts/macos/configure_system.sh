#!/usr/bin/env bash
# scripts/macos/configure_system.sh — macOS adapter (brew).
# Taps + formulae are handled by install.sh; here: casks, links, default shell.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/os.sh"
source "${SCRIPT_DIR}/../lib/link.sh"

main() {
    detect_os
    detect_profile
    _process "Configuring system (macOS, profiles: $PROFILES)"

    if [ -f "${DOTFILES_DIR}/opt/casks.txt" ]; then
        _process "Installing casks"
        while read -r cask; do
            [ -n "$cask" ] && case "$cask" in \#*) ;; *) brew install --cask "$cask" ;; esac
        done <"${DOTFILES_DIR}/opt/casks.txt"
    fi

    link_dotfiles
    # GitHub identity/key/gh-auth before dotpi clone (private repo needs the key)
    bash "${DOTFILES_DIR}/profiles/base/scripts/setup_github.sh" || true
    ensure_dotpi || true
    link_gitconfig || true
    link_zsh_config || true
    link_pi_config || true
    setup_zsh_as_default || true

    _success "System configuration complete (macOS)"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi