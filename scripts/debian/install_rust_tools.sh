#!/usr/bin/env bash
# Author: Eduardo Neville <eduadoneville82@gmail.com>
# Description: Install Rust and cargo packages

set -e

DOTFILES_DIR="${HOME}/dotfiles"

_process() { echo "$(tput setaf 6)→ $1...$(tput sgr0)"; }
_success() { echo "$(tput setaf 2)✓ Success:$(tput sgr0) $1"; }
_error() { echo "$(tput setaf 1)✗ Error:$(tput sgr0) $1"; }

install_rust() {
    _process "Installing Rust"

    if command -v rustc >/dev/null 2>&1; then
        _success "Rust is already installed ($(rustc --version))"
        read -p "Update Rust? (y/n): " update_rust
        if [[ "$update_rust" =~ ^[Yy]$ ]]; then
            rustup update
            _success "Rust updated"
        fi
        return 0
    fi

    _process "Downloading and installing Rust via rustup"
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable

    # Source cargo environment
    source "${HOME}/.cargo/env"

    _success "Rust installed successfully"
}

install_cargo_binstall() {
    _process "Installing cargo-binstall for faster package installation"

    if command -v cargo-binstall >/dev/null 2>&1; then
        _success "cargo-binstall already installed"
        return 0
    fi

    cargo install cargo-binstall

    _success "cargo-binstall installed"
}

install_cargo_packages() {
    _process "Installing cargo packages"

    # Ensure cargo is available
    source "${HOME}/.cargo/env" 2>/dev/null || true

    local cargo_file="${DOTFILES_DIR}/opt/cargoPkgs"

    if [ ! -f "$cargo_file" ]; then
        _error "Cargo packages file not found at $cargo_file"
        return 1
    fi

    # Read packages
    local packages=($(cat "$cargo_file" | grep -v '^#' | grep -v '^$'))

    if [ ${#packages[@]} -eq 0 ]; then
        _error "No packages found in $cargo_file"
        return 1
    fi

    _process "Installing ${#packages[@]} cargo packages"

    # Check if cargo-binstall is available
    if command -v cargo-binstall >/dev/null 2>&1; then
        _process "Using cargo-binstall for faster installation"

        for pkg in "${packages[@]}"; do
            echo "Installing $pkg..."
            cargo binstall -y "$pkg" || {
                echo "Falling back to cargo install for $pkg"
                cargo install "$pkg"
            }
        done
    else
        _process "Installing packages with cargo install"

        for pkg in "${packages[@]}"; do
            echo "Installing $pkg..."
            cargo install "$pkg"
        done
    fi

    _success "All cargo packages installed"
}

show_installed_packages() {
    _process "Installed cargo packages:"
    echo ""
    cargo install --list | grep -E "^[a-z]" | sed 's/ v.*//'
    echo ""
}

main() {
    _process "Rust Tools Installation"

    install_rust
    install_cargo_binstall
    install_cargo_packages

    # Show what was installed
    show_installed_packages

    _success "Rust tools installation complete"

    echo ""
    echo "Note: Make sure to source cargo environment in your shell:"
    echo "  source \$HOME/.cargo/env"
    echo ""
    echo "Or add this to your .zshrc or .bashrc:"
    echo "  export PATH=\"\$HOME/.cargo/bin:\$PATH\""
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
