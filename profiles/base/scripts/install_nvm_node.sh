#!/usr/bin/env bash
# Author: Eduardo Neville <eduadoneville82@gmail.com>
# Description: Install NVM and Node.js

set -e

_process() { echo "$(tput setaf 6)→ $1...$(tput sgr0)"; }
_success() { echo "$(tput setaf 2)✓ Success:$(tput sgr0) $1"; }
_error() { echo "$(tput setaf 1)✗ Error:$(tput sgr0) $1"; }

install_nvm() {
    _process "Installing NVM (Node Version Manager)"

    # Check if NVM is already installed
    if [ -d "${HOME}/.nvm" ]; then
        _success "NVM is already installed"
        return 0
    fi

    # Install NVM
    local NVM_VERSION="v0.40.1"
    curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash

    # Load NVM
    export NVM_DIR="${HOME}/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    _success "NVM installed successfully"
}

install_nodejs() {
    _process "Installing Node.js"

    # Load NVM
    export NVM_DIR="${HOME}/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    if ! command -v nvm >/dev/null 2>&1; then
        _error "NVM not found. Please install NVM first"
        return 1
    fi

    # Check if a Node version is already installed
    if nvm ls | grep -q "->"; then
        local current_version=$(nvm current)
        _success "Node.js is already installed ($current_version)"
        read -p "Install a different version? (y/n): " install_different
        if [[ ! "$install_different" =~ ^[Yy]$ ]]; then
            return 0
        fi
    fi

    # Ask which version to install
    echo "Which Node.js version would you like to install?"
    echo "1) Latest LTS (recommended)"
    echo "2) Latest stable"
    echo "3) Specific version (e.g., 24.9.0)"
    read -p "Select (1-3): " version_choice

    case $version_choice in
        1)
            _process "Installing latest LTS version"
            nvm install --lts
            nvm use --lts
            nvm alias default 'lts/*'
            ;;
        2)
            _process "Installing latest stable version"
            nvm install node
            nvm use node
            nvm alias default node
            ;;
        3)
            read -p "Enter Node.js version (e.g., 24.9.0): " specific_version
            _process "Installing Node.js $specific_version"
            nvm install "$specific_version"
            nvm use "$specific_version"
            nvm alias default "$specific_version"
            ;;
        *)
            _error "Invalid choice. Installing latest LTS"
            nvm install --lts
            nvm use --lts
            nvm alias default 'lts/*'
            ;;
    esac

    _success "Node.js installed successfully"
}

install_global_packages() {
    _process "Installing global npm packages"

    # Load NVM
    export NVM_DIR="${HOME}/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    # Essential global packages
    local packages=(
        "@anthropic-ai/claude-code"
        "typescript"
        "ts-node"
        "yarn"
        "pnpm"
    )

    for pkg in "${packages[@]}"; do
        _process "Installing $pkg"
        npm install -g "$pkg"
    done

    _success "Global npm packages installed"
}

show_node_info() {
    # Load NVM
    export NVM_DIR="${HOME}/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    echo ""
    echo "===== Node.js Information ====="
    echo "Node version: $(node --version)"
    echo "npm version: $(npm --version)"
    echo "nvm version: $(nvm --version)"
    echo ""
    echo "Installed global packages:"
    npm list -g --depth=0
    echo "==============================="
}

main() {
    _process "Node.js/NVM Installation"

    install_nvm
    install_nodejs
    install_global_packages

    show_node_info

    _success "Node.js/NVM installation complete"

    echo ""
    echo "Note: NVM has been added to your shell configuration."
    echo "Restart your terminal or run:"
    echo "  source ~/.zshrc  # or ~/.bashrc"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
