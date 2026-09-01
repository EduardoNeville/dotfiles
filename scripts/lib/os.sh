#!/usr/bin/env bash
# scripts/lib/os.sh — OS detection + package dispatcher (portable, no sudo assumptions)

detect_os() {
    if [ -f /etc/os-release ]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        OS="$ID"
    elif [ "$(uname)" = "Darwin" ]; then
        OS="macos"
    else
        OS="unknown"
    fi

    case "$OS" in
    ubuntu | debian) PKG="apt" ;;
    fedora | centos | rhel) PKG="dnf" ;;
    arch | manjaro) PKG="pacman" ;;
    void) PKG="xbps" ;;
    macos) PKG="brew" ;;
    *) PKG="unknown" ;;
    esac
}

has() { command -v "$1" >/dev/null 2>&1; }

# pkg_install <name> — install one package with the native package manager.
# Returns non-zero on failure; caller decides whether to continue.
pkg_install() {
    case "$PKG" in
    brew) brew install "$1" ;;
    apt) sudo apt-get install -y "$1" ;;
    dnf) sudo dnf install -y "$1" ;;
    pacman) sudo pacman -S --noconfirm "$1" ;;
    xbps) sudo xbps-install -y "$1" ;;
    *)
        _error "Unknown package manager: $PKG"
        return 1
        ;;
    esac
}
