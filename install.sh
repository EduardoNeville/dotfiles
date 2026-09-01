#!/usr/bin/env bash
# install.sh — single entrypoint, every OS.
#   ./install.sh               packages + links + parity check
#   ./install.sh --links-only  links + parity check (no package installs)
#   ./install.sh --check       parity check only
# Heavy tooling (rust, node, docker, wezterm builds) still lives in full_install.sh.

set -e

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
MODE="full"

for arg in "$@"; do
    case "$arg" in
    --links-only) MODE="links" ;;
    --check) MODE="check" ;;
    *) echo "unknown option: $arg (use --links-only | --check)" >&2; exit 2 ;;
    esac
done

export DOTFILES_DIR

# shellcheck source=scripts/lib/os.sh
source "${DOTFILES_DIR}/scripts/lib/os.sh"
# shellcheck source=scripts/lib/link.sh
source "${DOTFILES_DIR}/scripts/lib/link.sh"
# shellcheck source=scripts/lib/packages.sh
source "${DOTFILES_DIR}/scripts/lib/packages.sh"

detect_os
_process "Detected: $OS (package manager: $PKG)"

case "$MODE" in
check)
    ;;
full)
    case "$PKG" in
    brew)
        if [ -f "${DOTFILES_DIR}/opt/Brewfile" ]; then
            _process "Installing brew packages (Brewfile)"
            brew bundle --file="${DOTFILES_DIR}/opt/Brewfile" || _error "brew bundle had failures"
        fi
        ;;
    apt)
        sudo apt-get update
        ;;
    esac
    install_common_packages || _error "some common packages failed — see above"
    ;;
esac

if [ "$MODE" != "check" ]; then
    if [ -f "${DOTFILES_DIR}/scripts/${OS}/configure_system.sh" ]; then
        bash "${DOTFILES_DIR}/scripts/${OS}/configure_system.sh"
    else
        _error "No adapter for $OS — expected scripts/${OS}/configure_system.sh"
        exit 1
    fi
fi

_process "Running parity check"
bash "${DOTFILES_DIR}/scripts/check_parity.sh"
