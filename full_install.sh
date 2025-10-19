#!/usr/bin/env bash
# Author: Eduardo Neville <eduardoneville82@gmail.com>
# Description: Comprehensive automated dotfiles installation script
# Supports: Debian, Ubuntu, Void Linux, Fedora, MacOS

set -e

DOTFILES_DIR="${PWD}"
PACKAGE_MANAGER=""
OS=""
LOG_FILE="${HOME}/dotfiles_install.log"

# ============================================================================
# Utility Functions
# ============================================================================

_process() { echo "$(tput setaf 6)→ $1...$(tput sgr0)"; }
_success() { echo "$(tput setaf 2)✓ Success:$(tput sgr0) $1"; }
_error() { echo "$(tput setaf 1)✗ Error:$(tput sgr0) $1"; }
_prompt() { echo "$(tput setaf 3)? $1$(tput sgr0)"; }
_header() {
    echo ""
    echo "$(tput setaf 5)========================================$(tput sgr0)"
    echo "$(tput setaf 5)  $1$(tput sgr0)"
    echo "$(tput setaf 5)========================================$(tput sgr0)"
    echo ""
}

program_exists() { command -v "$1" >/dev/null 2>&1; }

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# ============================================================================
# OS Detection
# ============================================================================

detect_os() {
    _process "Detecting operating system"

    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS="$ID"
    elif command -v hostnamectl >/dev/null 2>&1; then
        OS=$(hostnamectl | grep "Operating System" | awk -F": " '{print $2}' | awk '{print $1}' | tr '[:upper:]' '[:lower:]')
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    else
        OS="unknown"
    fi

    case "$OS" in
        "ubuntu"|"debian")
            PACKAGE_MANAGER="apt"
            ;;
        "fedora"|"centos"|"rhel")
            PACKAGE_MANAGER="dnf"
            ;;
        "arch"|"manjaro")
            PACKAGE_MANAGER="pacman"
            ;;
        "void")
            PACKAGE_MANAGER="xbps"
            ;;
        "macos")
            PACKAGE_MANAGER="brew"
            ;;
        *)
            PACKAGE_MANAGER="unknown"
            ;;
    esac

    _success "Detected: $OS (Package manager: $PACKAGE_MANAGER)"
    log "OS detected: $OS, Package manager: $PACKAGE_MANAGER"
}

# ============================================================================
# Package Manager Installation & Update
# ============================================================================

install_package_manager() {
    _header "Package Manager Setup"

    case $PACKAGE_MANAGER in
        "brew")
            if ! program_exists brew; then
                _process "Installing Homebrew"
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
                _success "Homebrew installed"
            else
                _success "Homebrew already installed"
            fi
            ;;
        *)
            _success "Package manager already available"
            ;;
    esac
}

update_system() {
    _header "System Update"
    _process "Updating system packages"

    case $PACKAGE_MANAGER in
        "apt")
            sudo apt update && sudo apt upgrade -y
            ;;
        "dnf")
            sudo dnf upgrade -y
            ;;
        "pacman")
            sudo pacman -Syu --noconfirm
            ;;
        "xbps")
            sudo xbps-install -Su
            ;;
        "brew")
            brew update && brew upgrade
            ;;
        *)
            _error "Unsupported package manager"
            return 1
            ;;
    esac

    _success "System updated"
}

# ============================================================================
# Core Package Installation
# ============================================================================

install_packages() {
    _header "Installing Packages"

    local pkg_file=""

    case $PACKAGE_MANAGER in
        "apt")
            pkg_file="${DOTFILES_DIR}/opt/debianPkgs"
            ;;
        "dnf")
            pkg_file="${DOTFILES_DIR}/opt/dnfPkgs"
            ;;
        "xbps")
            pkg_file="${DOTFILES_DIR}/opt/xbpsPkgs"
            ;;
        "brew")
            if [ -f "${DOTFILES_DIR}/opt/Brewfile" ]; then
                _process "Installing packages via Brewfile"
                cd "${DOTFILES_DIR}/opt"
                brew bundle
                cd - >/dev/null
                _success "Brew packages installed"
                return 0
            fi
            pkg_file="${DOTFILES_DIR}/opt/brewPkgs"
            ;;
        *)
            _error "Unsupported package manager: $PACKAGE_MANAGER"
            return 1
            ;;
    esac

    if [ ! -f "$pkg_file" ]; then
        _error "Package file not found: $pkg_file"
        return 1
    fi

    _process "Installing packages from $pkg_file"

    # Read packages (filter out comments and empty lines)
    local packages=($(grep -v '^#' "$pkg_file" | grep -v '^$'))

    if [ ${#packages[@]} -eq 0 ]; then
        _error "No packages found in $pkg_file"
        return 1
    fi

    _process "Installing ${#packages[@]} packages (this may take a while)..."

    case $PACKAGE_MANAGER in
        "apt")
            sudo apt update
            sudo apt install -y "${packages[@]}" 2>&1 | tee -a "$LOG_FILE"
            ;;
        "dnf")
            sudo dnf install -y "${packages[@]}" 2>&1 | tee -a "$LOG_FILE"
            ;;
        "xbps")
            sudo xbps-install -y "${packages[@]}" 2>&1 | tee -a "$LOG_FILE"
            ;;
        "brew")
            brew install "${packages[@]}" 2>&1 | tee -a "$LOG_FILE"
            ;;
    esac

    _success "Packages installed successfully"
}

# ============================================================================
# Docker Installation
# ============================================================================

install_docker() {
    _header "Docker Installation"

    if program_exists docker; then
        _success "Docker already installed"
        return 0
    fi

    _process "Installing Docker"

    case $PACKAGE_MANAGER in
        "apt")
            # Install Docker on Debian/Ubuntu
            sudo apt-get update
            sudo apt-get install -y ca-certificates curl
            sudo install -m 0755 -d /etc/apt/keyrings
            sudo curl -fsSL https://download.docker.com/linux/${OS}/gpg -o /etc/apt/keyrings/docker.asc
            sudo chmod a+r /etc/apt/keyrings/docker.asc

            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/${OS} \
            $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
            sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

            sudo apt-get update
            sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

            # Add user to docker group
            sudo usermod -aG docker ${USER}
            ;;

        "dnf")
            sudo dnf -y install dnf-plugins-core
            sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
            sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            sudo systemctl enable --now docker
            sudo usermod -aG docker ${USER}
            ;;

        "xbps")
            sudo xbps-install -y docker
            sudo ln -s /etc/sv/docker /var/service/
            sudo usermod -aG docker ${USER}
            ;;

        "brew")
            brew install --cask docker
            ;;

        *)
            _error "Docker installation not supported for $PACKAGE_MANAGER"
            return 1
            ;;
    esac

    _success "Docker installed"
}

# ============================================================================
# Rust & Cargo
# ============================================================================

install_rust() {
    _header "Rust Installation"

    if [ -f "${DOTFILES_DIR}/scripts/${OS}/install_rust_tools.sh" ]; then
        bash "${DOTFILES_DIR}/scripts/${OS}/install_rust_tools.sh"
    elif [ -f "${DOTFILES_DIR}/scripts/debian/install_rust_tools.sh" ]; then
        bash "${DOTFILES_DIR}/scripts/debian/install_rust_tools.sh"
    else
        _process "Installing Rust (fallback method)"

        if ! program_exists rustc; then
            curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
            source "${HOME}/.cargo/env"
            _success "Rust installed"
        else
            _success "Rust already installed"
        fi

        # Install cargo packages
        if [ -f "${DOTFILES_DIR}/opt/cargoPkgs" ]; then
            _process "Installing cargo packages"
            source "${HOME}/.cargo/env" 2>/dev/null || true

            # Install cargo-binstall first for faster installations
            if ! program_exists cargo-binstall; then
                cargo install cargo-binstall
            fi

            local cargo_packages=($(cat "${DOTFILES_DIR}/opt/cargoPkgs" | grep -v '^#' | grep -v '^$'))
            for pkg in "${cargo_packages[@]}"; do
                cargo binstall -y "$pkg" 2>&1 | tee -a "$LOG_FILE" || cargo install "$pkg" 2>&1 | tee -a "$LOG_FILE"
            done
            _success "Cargo packages installed"
        fi
    fi
}

# ============================================================================
# Node.js & NPM
# ============================================================================

install_nodejs() {
    _header "Node.js Installation"

    if [ -f "${DOTFILES_DIR}/scripts/${OS}/install_nvm_node.sh" ]; then
        bash "${DOTFILES_DIR}/scripts/${OS}/install_nvm_node.sh"
    elif [ -f "${DOTFILES_DIR}/scripts/debian/install_nvm_node.sh" ]; then
        bash "${DOTFILES_DIR}/scripts/debian/install_nvm_node.sh"
    else
        _process "Installing NVM (fallback method)"
        if [ ! -d "${HOME}/.nvm" ]; then
            curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
            export NVM_DIR="${HOME}/.nvm"
            [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
            nvm install --lts
            nvm use --lts
            _success "Node.js installed"
        else
            _success "NVM already installed"
        fi
    fi
}

# ============================================================================
# Suckless Tools (dwm, slstatus, etc.)
# ============================================================================

install_suckless() {
    _header "Suckless Tools Installation"

    if [ -f "${DOTFILES_DIR}/scripts/${OS}/install_suckless.sh" ]; then
        bash "${DOTFILES_DIR}/scripts/${OS}/install_suckless.sh"
    elif [ -f "${DOTFILES_DIR}/scripts/debian/install_suckless.sh" ]; then
        bash "${DOTFILES_DIR}/scripts/debian/install_suckless.sh"
    else
        _error "No suckless installation script found for $OS"
    fi
}

# ============================================================================
# Audio Setup (PipeWire)
# ============================================================================

setup_audio() {
    _header "Audio System Setup"

    if [ -f "${DOTFILES_DIR}/scripts/${OS}/setup_audio.sh" ]; then
        bash "${DOTFILES_DIR}/scripts/${OS}/setup_audio.sh"
    elif [ -f "${DOTFILES_DIR}/scripts/debian/setup_audio.sh" ]; then
        bash "${DOTFILES_DIR}/scripts/debian/setup_audio.sh"
    else
        _error "No audio setup script found for $OS"
    fi
}

# ============================================================================
# GitHub Setup
# ============================================================================

setup_github() {
    _header "GitHub Authentication"

    if [ -f "${DOTFILES_DIR}/scripts/${OS}/setup_github.sh" ]; then
        bash "${DOTFILES_DIR}/scripts/${OS}/setup_github.sh"
    elif [ -f "${DOTFILES_DIR}/scripts/debian/setup_github.sh" ]; then
        bash "${DOTFILES_DIR}/scripts/debian/setup_github.sh"
    else
        _error "No GitHub setup script found for $OS"
    fi
}

# ============================================================================
# System Configuration
# ============================================================================

configure_system() {
    _header "System Configuration"

    if [ -f "${DOTFILES_DIR}/scripts/${OS}/configure_system.sh" ]; then
        bash "${DOTFILES_DIR}/scripts/${OS}/configure_system.sh"
    elif [ -f "${DOTFILES_DIR}/scripts/debian/configure_system.sh" ]; then
        bash "${DOTFILES_DIR}/scripts/debian/configure_system.sh"
    else
        _error "No system configuration script found for $OS"
    fi
}

# ============================================================================
# Interactive Installation Menu
# ============================================================================

interactive_install() {
    _header "Dotfiles Installation"

    echo "What would you like to install?"
    echo ""
    echo "  1) Full automated installation (recommended)"
    echo "  2) System update only"
    echo "  3) Core packages"
    echo "  4) Docker"
    echo "  5) Rust & Cargo tools"
    echo "  6) Node.js & NPM"
    echo "  7) Suckless tools (dwm, slstatus, etc.)"
    echo "  8) Audio system (PipeWire)"
    echo "  9) GitHub setup & authentication"
    echo " 10) System configuration & dotfiles linking"
    echo ""
    echo "  0) Exit"
    echo ""
    read -p "Select option (or multiple separated by spaces): " -a choices

    for choice in "${choices[@]}"; do
        case $choice in
            1)
                full_install
                ;;
            2)
                update_system
                ;;
            3)
                install_packages
                ;;
            4)
                install_docker
                ;;
            5)
                install_rust
                ;;
            6)
                install_nodejs
                ;;
            7)
                install_suckless
                ;;
            8)
                setup_audio
                ;;
            9)
                setup_github
                ;;
            10)
                configure_system
                ;;
            0)
                echo "Exiting..."
                exit 0
                ;;
            *)
                _error "Invalid option: $choice"
                ;;
        esac
    done

    _success "Installation complete!"
}

# ============================================================================
# Full Automated Installation
# ============================================================================

full_install() {
    _header "Full Automated Installation"

    _process "Starting comprehensive installation"
    log "Starting full installation"

    # Core system setup
    install_package_manager
    update_system
    install_packages

    # Development tools
    install_docker
    install_rust
    install_nodejs

    # Desktop environment (if on Linux with X11/Wayland)
    if [[ "$OS" != "macos" ]] && [[ -n "$DISPLAY" || -n "$WAYLAND_DISPLAY" ]]; then
        read -p "Install desktop environment (suckless/dwm)? (y/n): " install_de
        if [[ "$install_de" =~ ^[Yy]$ ]]; then
            install_suckless
        fi
    fi

    # Audio setup (Linux only)
    if [[ "$OS" != "macos" ]]; then
        read -p "Setup audio system (PipeWire)? (y/n): " setup_audio_prompt
        if [[ "$setup_audio_prompt" =~ ^[Yy]$ ]]; then
            setup_audio
        fi
    fi

    # GitHub authentication
    read -p "Setup GitHub authentication? (y/n): " setup_gh
    if [[ "$setup_gh" =~ ^[Yy]$ ]]; then
        setup_github
    fi

    # System configuration and dotfiles
    configure_system

    log "Full installation completed successfully"
    _success "Full installation complete!"

    echo ""
    echo "============================================"
    echo "  Installation Summary"
    echo "============================================"
    echo "✓ System updated"
    echo "✓ Packages installed"
    echo "✓ Development tools configured"
    echo "✓ Dotfiles linked"
    echo ""
    echo "Please log out and log back in for all changes to take effect."
    echo ""
    echo "Installation log saved to: $LOG_FILE"
    echo "============================================"
}

# ============================================================================
# Unattended Installation
# ============================================================================

unattended_install() {
    _header "Unattended Installation"
    _process "Running unattended installation (no prompts)"

    log "Starting unattended installation"

    install_package_manager
    update_system
    install_packages
    install_docker
    install_rust
    install_nodejs

    # Skip desktop environment and audio setup in unattended mode
    # Skip GitHub setup (requires authentication)

    configure_system

    log "Unattended installation completed"
    _success "Unattended installation complete!"
}

# ============================================================================
# Main
# ============================================================================

main() {
    # Initialize log file
    echo "Installation started at $(date)" > "$LOG_FILE"

    # ASCII Art Banner
    echo ""
    echo "╔══════════════════════════════════════════════╗"
    echo "║                                              ║"
    echo "║     Dotfiles Installation Script             ║"
    echo "║     by Eduardo Neville                       ║"
    echo "║                                              ║"
    echo "╚══════════════════════════════════════════════╝"
    echo ""

    detect_os

    # Check for flags
    if [[ "$1" == "--unattended" ]] || [[ "$1" == "-u" ]]; then
        unattended_install
    elif [[ "$1" == "--full" ]] || [[ "$1" == "-f" ]]; then
        full_install
    elif [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
        echo "Usage: $0 [OPTIONS]"
        echo ""
        echo "Options:"
        echo "  --full, -f         Run full automated installation"
        echo "  --unattended, -u   Run unattended installation (no prompts)"
        echo "  --help, -h         Show this help message"
        echo ""
        echo "No options: Interactive menu"
        exit 0
    else
        interactive_install
    fi
}

# Make helper scripts executable
chmod +x "${DOTFILES_DIR}/scripts/debian"/*.sh 2>/dev/null || true

# Run main
main "$@"
