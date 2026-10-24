#!/usr/bin/env bash
# scripts/lib/link.sh — OS-agnostic config linking engine.
# This is the ONLY place that creates config symlinks. Adapters source it.

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"

# backup_then_link <existing-target> <source> — replace real files with a
# timestamped backup, replace symlinks silently.
backup_then_link() {
    local target="$1" src="$2"
    if [ -e "$target" ] && [ ! -L "$target" ]; then
        _process "Backing up existing $target"
        mv "$target" "${target}.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    [ -L "$target" ] && rm "$target"
    ln -sf "$src" "$target"
}

# ensure_dotpi — clone the pi agent config repo (separate repo, canonical
# source for settings/trust/extensions). Try ssh (keyed) then https. Both
# attempts run with GIT_TERMINAL_PROMPT=0 and a timeout so a private repo
# without a key fails in seconds instead of blocking the installer on a
# credential prompt, or hanging on an unreachable network.
# The pi config repo is its own repository at the root of $HOME (a peer of
# ~/dotfiles), never nested inside dotfiles. Any host can point at a different
# config repo/location: DOTPI_REPO=<url> DOTPI_DIR=~/pi-config ./install.sh
DOTPI_REPO="${DOTPI_REPO:-git@github.com:EduardoNeville/dotpi.git}"
DOTPI_DIR="${DOTPI_DIR:-${HOME}/dotpi}"
ensure_dotpi() {
    # A directory is not enough — a killed clone leaves one behind, so require
    # dotpi's own marker file before declaring it present.
    if [ -f "${DOTPI_DIR}/settings.json" ]; then
        return 0
    fi

    _process "Cloning pi config repo into ${DOTPI_DIR}"
    mkdir -p "$(dirname "${DOTPI_DIR}")"

    local timeout_cmd=""
    has timeout && timeout_cmd="timeout ${DOTPI_CLONE_TIMEOUT:-90}"
    local https_repo="${DOTPI_REPO/git@github.com:/https://github.com/}"
    local cloned=0

    if ${timeout_cmd} env GIT_TERMINAL_PROMPT=0 git clone --recurse-submodules "${DOTPI_REPO}" "${DOTPI_DIR}" 2>/dev/null; then
        cloned=1
    elif [ "${https_repo}" != "${DOTPI_REPO}" ] &&
        ${timeout_cmd} env GIT_TERMINAL_PROMPT=0 git clone --recurse-submodules "${https_repo}" "${DOTPI_DIR}" 2>/dev/null; then
        cloned=1
    fi

    if [ "$cloned" -eq 1 ]; then
        _success "pi config repo cloned"
        return 0
    fi

    # Nothing was there before this function ran, so a leftover directory can
    # only be a partial clone from the attempt above.
    rm -rf "${DOTPI_DIR}"
    _error "clone failed — run profiles/base/scripts/setup_github.sh first (private repo), then re-run install.sh"
    return 1
}

link_dotfiles() {
    _process "Symlinking dotfiles"

    # Create .config directory if it doesn't exist
    mkdir -p "${HOME}/.config"

    # Symlink each universal config directory
    for item in "${DOTFILES_DIR}/configs"/*; do
        [ -d "$item" ] || continue # Skip if not a directory
        local basename=$(basename "$item")
        [ "$basename" = "ssh" ] && continue # special-cased below
        backup_then_link "${HOME}/.config/${basename}" "$item"
        echo "  ✓ Linked $basename"
    done

    # Symlink each active profile's config directories
    local p item
    for p in $PROFILES; do
        for item in "${DOTFILES_DIR}/profiles/$p/configs"/*; do
            [ -e "$item" ] || continue
            local basename=$(basename "$item")
            # File-level X session dotfiles, not ~/.config/<name>/:
            #   xinitrc  — startx
            #   xsession — /etc/X11/Xsession (Debian's generic "Default Xsession"
            #              entry), which without it falls back to a bare terminal
            case "$basename" in
            xinitrc|xsession)
                backup_then_link "${HOME}/.${basename}" "$item"
                echo "  ✓ Linked .${basename} ($p)"
                continue
                ;;
            esac
            [ -d "$item" ] || continue
            backup_then_link "${HOME}/.config/${basename}" "$item"
            echo "  ✓ Linked $basename ($p)"
        done
    done

    # ssh config lives at ~/.ssh/config, not ~/.config/ssh
    if [ -f "${DOTFILES_DIR}/configs/ssh/config" ]; then
        mkdir -p "${HOME}/.ssh"
        backup_then_link "${HOME}/.ssh/config" "${DOTFILES_DIR}/configs/ssh/config"
        echo "  ✓ Linked .ssh/config"
    fi

    _success "Config directories linked"
}

link_zsh_config() {
    _process "Linking ZSH configuration"

    local zshrc="${DOTFILES_DIR}/configs/zsh-conf/zshrc"
    local zprofile="${DOTFILES_DIR}/configs/zsh-conf/zprofile"

    if [ -f "$zshrc" ]; then
        backup_then_link "${HOME}/.zshrc" "$zshrc"
        _success "ZSH config linked"
    else
        _error "ZSH config not found at $zshrc"
    fi

    if [ -f "$zprofile" ]; then
        backup_then_link "${HOME}/.zprofile" "$zprofile"
        echo "  ✓ Linked .zprofile (login shells; startx only on desktop profile)"
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

        backup_then_link "${HOME}/.gitconfig" "$gitconfig"
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

    if ! has zsh; then
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
        # Best-effort: a stale gitlink must not abort the whole install
        git submodule update --init --recursive || _error "git submodule update failed (continuing)"
        _success "ZSH plugins updated"
    fi

    cd - >/dev/null
}

install_starship() {
    _process "Installing Starship prompt"

    if has starship; then
        _success "Starship already installed"
        return 0
    fi

    # Check if it's in cargo packages
    if has cargo; then
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
    if has nvim; then
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

link_pi_config() {
    _process "Linking Pi agent configuration"

    # The config repo owns ~/.pi/agent (see its install.sh); dotfiles ships no
    # pi config and does not duplicate its linking rules.
    if [ -f "${DOTPI_DIR}/install.sh" ]; then
        _process "Delegating to ${DOTPI_DIR}/install.sh (canonical pi config)"
        # --no-extensions: extension npm installs are handled by dotpi or
        # caller explicitly; configure_system stays fast and offline-safe.
        sh "${DOTPI_DIR}/install.sh" --no-extensions || {
            _error "${DOTPI_DIR}/install.sh failed — check ${DOTPI_DIR}/install.sh --dry-run"
            return 1
        }
        _success "Pi agent configuration linked via the config repo"
        return 0
    fi

    # A missing install.sh here means the clone failed (private repo without an
    # SSH key) — say that instead of half-configuring pi.
    _error "${DOTPI_DIR} has no install.sh — pi config not linked; run profiles/base/scripts/setup_github.sh (or clone ${DOTPI_REPO} manually), then re-run install.sh"
    return 1
}

# link_all — the complete engine pass, shared by every OS adapter.
link_all() {
    _process "Linking configuration (engine)"

    create_common_directories
    link_dotfiles
    link_zsh_config
    link_gitconfig
    link_pi_config
    install_zsh_plugins
    setup_zsh_as_default
    install_starship
    setup_vim

    _success "Engine: all configs linked"
}
