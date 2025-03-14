# Author: Eduardo Neville <eduadoneville82@gmail.com>
#!/usr/bin/env bash
# Description:
# Automatically install tools for different OS
source $(dirname "$0")/scripts/installer.sh

DOTFILES_DIR="${HOME}/dotfiles"
PACKAGE_MANAGER=""
LOG="${HOME}/Library/Logs/dotfiles.log"

# Detect the operating system
case "$(uname)" in
    "Linux")  PACKAGE_MANAGER="apt"  ;;
    "Darwin") PACKAGE_MANAGER="brew" ;;
esac

_process() { echo "$(tput setaf 6)→ $1...$(tput sgr0)"; }
_success() { echo "$(tput setaf 2)✓ Success:$(tput sgr0) $1"; }
_error() { echo "$(tput setaf 1)✗ Error:$(tput sgr0) $1"; }

# Check if a program exists
program_exists() { command -v "$1" >/dev/null 2>&1; }

# Install Docker
install_docker() {
    _process "Installing Docker"

    if [[ "$PACKAGE_MANAGER" == "brew" ]]; then
        brew install --cask docker
        _success "Docker installed via Homebrew"
        return
    elif [[ "$PACKAGE_MANAGER" == "apt" ]]; then
        _process "Setting up Docker's apt repository"

        sudo apt-get update
        sudo apt-get install -y ca-certificates curl

        sudo install -m 0755 -d /etc/apt/keyrings
        sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
        sudo chmod a+r /etc/apt/keyrings/docker.asc

        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
        $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

        sudo apt-get update

        _process "Installing Docker Engine"
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

        _success "Docker installed successfully"
    else
        _error "Unsupported OS for Docker installation"
    fi
}

# Symlink dotfiles
link_dotfiles() {
    _process "Symlinking dotfiles"
    mkdir -p "${HOME}/.config"

    for item in "${DOTFILES_DIR}/configs"/*; do
        target="${HOME}/.config/$(basename "$item")"
        [ ! -e "$target" ] && ln -s "$item" "$target"
    done

    ln -sf "${DOTFILES_DIR}/configs/zsh-conf/zshrc" ~/.zshrc
    _success "Dotfiles are linked"
}

# Install a package manager
install_package_manager() {
    case $PACKAGE_MANAGER in
        "brew")
            _process "Installing Homebrew"
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
            brew doctor && _success "Homebrew installed"
            ;;
        "apt")
            _process "Updating APT"
            sudo apt update && sudo apt upgrade -y
            _success "APT updated"
            ;;
    esac
}

# Install packages from a file
install_packages() {
    local file="$DOTFILES_DIR/opt/$1"
    [[ ! -f "$file" ]] && _error "File $file not found" && return

    _process "Installing packages from $file"
    local packages=($(cat "$file"))

    case $PACKAGE_MANAGER in
        "brew") brew install "${packages[@]}" ;;
        "apt") sudo apt install -y "${packages[@]}" ;;
        "dnf") sudo dnf install -y "${packages[@]}" ;;
    esac

    _success "Installed packages from $file"
}

# Install Zsh plugins
install_zsh_plugins() {
    _process "Installing ZSH plugins"
    local zsh_dir="${DOTFILES_DIR}/configs/.config/zsh-conf"
    rm -rf "${zsh_dir}"
    git clone --recursive git@github.com:EduardoNeville/zsh-conf.git "${zsh_dir}"
    ln -fs "${zsh_dir}/.zshrc" "${HOME}/.zshrc"
    source ~/.zshrc
    _success "ZSH plugins installed"
}

# Install Lazy.nvim for Neovim
install_lazy_nvim() {
    _process "Installing Lazy.nvim for Neovim"
    
    local lazy_dir="${HOME}/.local/share/nvim/site/pack/lazy/start/lazy.nvim"
    rm -rf "$lazy_dir"  # Ensure a clean install

    git clone --filter=blob:none --branch=stable https://github.com/folke/lazy.nvim.git "$lazy_dir"
    
    _success "Lazy.nvim installed"
}

# Install Neovim plugins using Lazy.nvim
install_nvim_plugins() {
    _process "Running Neovim in headless mode to install plugins"

    # Ensure Neovim is installed
    if ! program_exists nvim; then
        _error "Neovim is not installed. Please install it first."
        return
    fi

    # Run Neovim headless and trigger plugin installation
    nvim --headless "+Lazy! sync" +qall

    _success "All Neovim plugins installed via Lazy.nvim"
}

# Install Rust and Cargo packages
install_rust() {
    _process "Installing Rust"
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

    source "$HOME/.cargo/env"

    local cargo_file="$DOTFILES_DIR/opt/cargoPkgs"
    [[ -f "$cargo_file" ]] && _process "Installing Cargo packages" && cargo install $(cat "$cargo_file") && _success "Cargo packages installed"
}

# Install Pyenv
install_pyenv() {
    _process "Installing Pyenv"
    git clone https://github.com/pyenv/pyenv.git ~/.pyenv
    sudo "${PACKAGE_MANAGER}" install -y \
        zlib-devel bzip2 bzip2-devel readline-devel \
        sqlite sqlite-devel openssl-devel xz xz-devel libffi-devel
    _success "Pyenv installed"
}

# Installation process
install() {
    local options=("Package Manager" "Packages" "Links" "Zsh Plugins" "Lazy.nvim" "Neovim Plugins" "Rust" "Pyenv" "Docker")
    local functions=(install_package_manager install_packages link_dotfiles install_zsh_plugins install_lazy_nvim install_nvim_plugins install_rust install_pyenv install_docker)

    echo "Select what to install:"
    for i in "${!options[@]}"; do
        echo "$i) ${options[$i]}"
    done
    echo "Enter multiple numbers separated by spaces (e.g., 0 2 5):"
    read -a choices

    for choice in "${choices[@]}"; do 
        ${functions[$choice]}
    done
}

install
