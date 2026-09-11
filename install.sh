#!/usr/bin/env bash
# install.sh — single entrypoint, every OS, profile-driven.
#   ./install.sh                     full install (default): sources → packages → configure → parity
#   ./install.sh --links-only        links + parity (no package installs)
#   ./install.sh --check             parity check only
#   ./install.sh --profile base,desktop   explicit profile override
# Profile resolution: --profile > $PROFILE > hosts/<hostname> > "base".
# Source builds (opt/source, nvim/tmux) and apt sources are handled inside
# the adapters — this file only orchestrates.

set -e

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
MODE="full"
PROFILE=""

while [ $# -gt 0 ]; do
    case "$1" in
    --links-only) MODE="links" ;;
    --check) MODE="check" ;;
    --profile) PROFILE="$2"; shift ;;
    *) echo "unknown option: $1 (--links-only | --check | --profile p1,p2)" >&2; exit 2 ;;
    esac
    shift
done

export DOTFILES_DIR PROFILE

# shellcheck source=scripts/lib/os.sh
source "${DOTFILES_DIR}/scripts/lib/os.sh"
# shellcheck source=scripts/lib/link.sh
source "${DOTFILES_DIR}/scripts/lib/link.sh"
# shellcheck source=scripts/lib/packages.sh
source "${DOTFILES_DIR}/scripts/lib/packages.sh"
# shellcheck source=scripts/lib/apt_sources.sh
source "${DOTFILES_DIR}/scripts/lib/apt_sources.sh"

detect_os
detect_profile

case "$MODE" in
check) ;;
full)
    case "$PKG" in
    apt)
        setup_apt_sources
        ;;
    brew)
        if [ -f "${DOTFILES_DIR}/opt/taps.txt" ]; then
            _process "Applying brew taps"
            xargs -a "${DOTFILES_DIR}/opt/taps.txt" brew tap
        fi
        ;;
    esac
    install_profile_packages || _error "some packages failed — see above"
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