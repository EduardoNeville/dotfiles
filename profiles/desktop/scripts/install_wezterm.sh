#!/usr/bin/env bash
# wezterm — stable terminal, installed from the GitHub release .deb (Tier 3).
# The fury.io apt repo is nightly-only with unsigned metadata — not used.
# Pinned stable version (20240203 line is the current stable; wezterm moves slow).
# Bump WEZ_VERSION here + re-run; manual bump is the note for the review loop.

set -e
_process() { echo "$(tput setaf 6)→ $1...$(tput sgr0)"; }
_success() { echo "$(tput setaf 2)✓ Success:$(tput sgr0) $1"; }
_error() { echo "$(tput setaf 1)✗ Error:$(tput sgr0) $1"; }
has() { command -v "$1" >/dev/null 2>&1; }

WEZ_VERSION="20240203-110809-5046fc22"

install_wezterm() {
    if has wezterm; then
        _success "wezterm present ($(wezterm --version 2>/dev/null | head -1))"
        return 0
    fi
    local url="https://github.com/wez/wezterm/releases/download/${WEZ_VERSION}/wezterm-${WEZ_VERSION}.Debian12.deb"
    _process "Downloading wezterm ${WEZ_VERSION} (stable .deb, Debian12 build)"
    curl -fL "$url" -o /tmp/wezterm.deb || {
        _error "wezterm download failed ($url)"
        return 1
    }
    sudo apt-get install -y /tmp/wezterm.deb
    rm -f /tmp/wezterm.deb
    _success "wezterm installed (dwm's Mod+Shift+Return terminal)"
}

main() {
    install_wezterm
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi