#!/usr/bin/env bash
# scripts/lib/os.sh — OS detection + package dispatcher (portable, no sudo assumptions)

_process() { echo "$(tput setaf 6)→ $1...$(tput sgr0)"; }
_success() { echo "$(tput setaf 2)✓ Success:$(tput sgr0) $1"; }
_error() { echo "$(tput setaf 1)✗ Error:$(tput sgr0) $1"; }
_prompt() { echo "$(tput setaf 3)? $1$(tput sgr0)"; }

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

HOST="$(hostname 2>/dev/null || echo unknown)"

# detect_profile — which profiles this machine activates.
# Order: $PROFILE env/--profile flag > hosts/<hostname>/PROFILE (dir style)
# or hosts/<hostname> file (legacy) > default "base".
detect_profile() {
    PROFILES="${PROFILE:-}"
    if [ -z "$PROFILES" ] && [ -f "${DOTFILES_DIR}/hosts/${HOST}/PROFILE" ]; then
        PROFILES="$(sed "s/^PROFILE=//" "${DOTFILES_DIR}/hosts/${HOST}/PROFILE" | tr -d '"')"
    elif [ -z "$PROFILES" ] && [ -f "${DOTFILES_DIR}/hosts/${HOST}" ]; then
        PROFILES="$(grep '^PROFILE=' "${DOTFILES_DIR}/hosts/${HOST}" | head -1 | cut -d= -f2- | tr -d '"')"
    fi
    PROFILES="${PROFILES:-base}"
    _process "Profiles: $PROFILES ($OS / $PKG)"
}

has() { command -v "$1" >/dev/null 2>&1; }

# pkg_install <name> — install one package with the native package manager.
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