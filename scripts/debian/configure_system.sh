#!/usr/bin/env bash
# Author: Eduardo Neville <eduadoneville82@gmail.com>
# Description: Configure Debian system settings and symlink dotfiles

set -e

DOTFILES_DIR="${HOME}/dotfiles"

_process() { echo "$(tput setaf 6)→ $1...$(tput sgr0)"; }
_success() { echo "$(tput setaf 2)✓ Success:$(tput sgr0) $1"; }
_error() { echo "$(tput setaf 1)✗ Error:$(tput sgr0) $1"; }
_prompt() { echo "$(tput setaf 3)? $1$(tput sgr0)"; }

link_dotfiles() {
    _process "Symlinking dotfiles"

    # Create .config directory if it doesn't exist
    mkdir -p "${HOME}/.config"

    # Symlink each config directory
    for item in "${DOTFILES_DIR}/configs"/*; do
        [ -d "$item" ] || continue  # Skip if not a directory

        local basename=$(basename "$item")
        local target="${HOME}/.config/${basename}"

        # Skip certain directories
        case "$basename" in
            "suckless"|"services")
                continue
                ;;
        esac

        # Backup existing directory/file
        if [ -e "$target" ] && [ ! -L "$target" ]; then
            _process "Backing up existing $basename"
            mv "$target" "${target}.backup.$(date +%Y%m%d_%H%M%S)"
        fi

        # Remove existing symlink
        [ -L "$target" ] && rm "$target"

        # Create new symlink
        ln -sf "$item" "$target"
        echo "  ✓ Linked $basename"
    done

    _success "Config directories linked"
}

link_zsh_config() {
    _process "Linking ZSH configuration"

    local zshrc="${DOTFILES_DIR}/configs/zsh-conf/zshrc"

    if [ -f "$zshrc" ]; then
        # Backup existing .zshrc
        if [ -f "${HOME}/.zshrc" ] && [ ! -L "${HOME}/.zshrc" ]; then
            mv "${HOME}/.zshrc" "${HOME}/.zshrc.backup.$(date +%Y%m%d_%H%M%S)"
        fi

        [ -L "${HOME}/.zshrc" ] && rm "${HOME}/.zshrc"
        ln -sf "$zshrc" "${HOME}/.zshrc"
        _success "ZSH config linked"
    else
        _error "ZSH config not found at $zshrc"
    fi
}

link_gitconfig() {
    _process "Linking git configuration"

    local gitconfig="${DOTFILES_DIR}/configs/.gitconfig"

    if [ -f "$gitconfig" ]; then
        # Don't overwrite if user already has custom git config
        if [ -f "${HOME}/.gitconfig" ] && ! [ -L "${HOME}/.gitconfig" ]; then
            read -p "Overwrite existing .gitconfig? (y/n): " overwrite_git
            if [[ ! "$overwrite_git" =~ ^[Yy]$ ]]; then
                _process "Keeping existing .gitconfig"
                return 0
            fi
            mv "${HOME}/.gitconfig" "${HOME}/.gitconfig.backup.$(date +%Y%m%d_%H%M%S)"
        fi

        [ -L "${HOME}/.gitconfig" ] && rm "${HOME}/.gitconfig"
        ln -sf "$gitconfig" "${HOME}/.gitconfig"
        _success "Git config linked"
    fi
}

setup_zsh_as_default() {
    _process "Setting ZSH as default shell"

    local current_shell=$(basename "$SHELL")

    if [ "$current_shell" = "zsh" ]; then
        _success "ZSH is already the default shell"
        return 0
    fi

    if ! command -v zsh >/dev/null 2>&1; then
        _error "ZSH is not installed"
        return 1
    fi

    local zsh_path=$(which zsh)

    # Check if zsh is in /etc/shells
    if ! grep -q "^${zsh_path}$" /etc/shells; then
        _process "Adding ZSH to /etc/shells"
        echo "$zsh_path" | sudo tee -a /etc/shells
    fi

    _process "Changing default shell to ZSH (requires password)"
    chsh -s "$zsh_path"

    _success "ZSH set as default shell (restart terminal to apply)"
}

install_zsh_plugins() {
    _process "Installing ZSH plugins"

    local zsh_plugins_dir="${DOTFILES_DIR}/configs/zsh-conf/plugins"

    if [ ! -d "$zsh_plugins_dir" ]; then
        _error "ZSH plugins directory not found"
        return 1
    fi

    # Plugins are likely already in the dotfiles as submodules
    # Just ensure they're updated
    cd "${DOTFILES_DIR}"

    if [ -d ".git" ]; then
        _process "Updating git submodules for ZSH plugins"
        git submodule update --init --recursive
        _success "ZSH plugins updated"
    fi

    cd - >/dev/null
}

install_starship() {
    _process "Installing Starship prompt"

    if command -v starship >/dev/null 2>&1; then
        _success "Starship already installed"
        return 0
    fi

    # Check if it's in cargo packages
    if command -v cargo >/dev/null 2>&1; then
        _process "Installing Starship via cargo"
        cargo install starship
    else
        _process "Installing Starship via official installer"
        curl -sS https://starship.rs/install.sh | sh -s -- -y
    fi

    _success "Starship installed"
}

setup_vim() {
    _process "Setting up Vim/Neovim"

    # Install Lazy.nvim for Neovim
    if command -v nvim >/dev/null 2>&1; then
        local lazy_dir="${HOME}/.local/share/nvim/site/pack/lazy/start/lazy.nvim"

        if [ ! -d "$lazy_dir" ]; then
            _process "Installing Lazy.nvim"
            git clone --filter=blob:none --branch=stable \
                https://github.com/folke/lazy.nvim.git "$lazy_dir"
            _success "Lazy.nvim installed"
        fi

        _process "Syncing Neovim plugins (this may take a moment)"
        nvim --headless "+Lazy! sync" +qall 2>/dev/null || true
        _success "Neovim plugins synchronized"
    fi
}

add_user_to_groups() {
    _process "Adding user to necessary groups"

    local groups=("video" "audio" "input" "docker" "storage")

    for group in "${groups[@]}"; do
        if getent group "$group" >/dev/null; then
            if ! groups ${USER} | grep -q "$group"; then
                sudo usermod -aG "$group" ${USER}
                echo "  ✓ Added to $group"
            fi
        fi
    done

    _success "User groups configured"
}

setup_fonts() {
    _process "Updating font cache"

    fc-cache -fv >/dev/null 2>&1

    _success "Font cache updated"
}

create_common_directories() {
    _process "Creating common directories"

    local dirs=(
        "${HOME}/Projects"
        "${HOME}/Documents"
        "${HOME}/Downloads"
        "${HOME}/.local/bin"
        "${HOME}/.local/share"
    )

    for dir in "${dirs[@]}"; do
        mkdir -p "$dir"
    done

    _success "Common directories created"
}

setup_systemd_user_services() {
    _process "Setting up systemd user services"

    local services_dir="${DOTFILES_DIR}/configs/services"

    if [ -d "$services_dir" ]; then
        mkdir -p "${HOME}/.config/systemd/user"

        for service in "$services_dir"/*.service; do
            [ -f "$service" ] || continue
            local service_name=$(basename "$service")
            ln -sf "$service" "${HOME}/.config/systemd/user/$service_name"
            echo "  ✓ Linked $service_name"
        done

        systemctl --user daemon-reload
        _success "Systemd user services configured"
    fi
}

main() {
    _process "Configuring system"

    # Link configuration files
    link_dotfiles
    link_zsh_config
    link_gitconfig

    # Setup shell
    install_zsh_plugins
    setup_zsh_as_default

    # Setup applications
    install_starship
    setup_vim

    # System configuration
    add_user_to_groups
    setup_fonts
    create_common_directories
    setup_systemd_user_services

    _success "System configuration complete"

    echo ""
    echo "Configuration Summary:"
    echo "  ✓ Dotfiles linked"
    echo "  ✓ ZSH configured"
    echo "  ✓ Neovim set up"
    echo "  ✓ Starship prompt installed"
    echo "  ✓ User groups updated"
    echo ""
    echo "NOTE: Log out and log back in for all changes to take effect"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
