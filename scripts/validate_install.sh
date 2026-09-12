#!/usr/bin/env bash
# Author: Eduardo Neville <eduadoneville82@gmail.com>
# Description: Validate dotfiles installation

set -e

_check() { echo -n "$(tput setaf 6)→ Checking $1...$(tput sgr0) "; }
_ok() { echo "$(tput setaf 2)✓$(tput sgr0)"; }
_fail() { echo "$(tput setaf 1)✗$(tput sgr0)"; }
_warn() { echo "$(tput setaf 3)⚠$(tput sgr0)"; }

validate_core_tools() {
    echo ""
    echo "===== Core Tools ====="

    local tools=("git" "curl" "wget" "zsh" "vim" "nvim")

    for tool in "${tools[@]}"; do
        _check "$tool"
        if command -v "$tool" >/dev/null 2>&1; then
            _ok
        else
            _fail
        fi
    done
}

validate_rust_tools() {
    echo ""
    echo "===== Rust Tools ====="

    _check "rustc"
    if command -v rustc >/dev/null 2>&1; then
        _ok
        echo "  Version: $(rustc --version)"
    else
        _warn
    fi

    _check "cargo"
    if command -v cargo >/dev/null 2>&1; then
        _ok
        echo "  Version: $(cargo --version)"
    else
        _warn
    fi

    local cargo_tools=("bat" "eza" "ripgrep" "fd" "zoxide" "starship" "git-delta" "gitui")
    for tool in "${cargo_tools[@]}"; do
        _check "$tool"
        if command -v "$tool" >/dev/null 2>&1; then
            _ok
        else
            _warn
        fi
    done
}

validate_nodejs() {
    echo ""
    echo "===== Node.js ====="

    _check "nvm"
    if [ -d "${HOME}/.nvm" ]; then
        _ok
        export NVM_DIR="${HOME}/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        echo "  Version: $(nvm --version 2>/dev/null || echo 'N/A')"
    else
        _warn
    fi

    _check "node"
    if command -v node >/dev/null 2>&1; then
        _ok
        echo "  Version: $(node --version)"
    else
        _warn
    fi

    _check "npm"
    if command -v npm >/dev/null 2>&1; then
        _ok
        echo "  Version: $(npm --version)"
    else
        _warn
    fi
}

validate_docker() {
    echo ""
    echo "===== Docker ====="

    _check "docker"
    if command -v docker >/dev/null 2>&1; then
        _ok
        echo "  Version: $(docker --version)"

        _check "docker service"
        if systemctl is-active --quiet docker 2>/dev/null || docker info >/dev/null 2>&1; then
            _ok
        else
            _warn
        fi
    else
        _warn
    fi
}

validate_window_manager() {
    echo ""
    echo "===== Window Manager ====="

    _check "dwm"
    if command -v dwm >/dev/null 2>&1; then
        _ok
    else
        _warn
    fi

    _check "slstatus"
    if command -v slstatus >/dev/null 2>&1; then
        _ok
    else
        _warn
    fi

    _check "i3"
    if command -v i3 >/dev/null 2>&1; then
        _ok
    else
        _warn
    fi

    _check "sway"
    if command -v sway >/dev/null 2>&1; then
        _ok
    else
        _warn
    fi
}

validate_audio() {
    echo ""
    echo "===== Audio System ====="

    _check "pipewire"
    if systemctl --user is-active --quiet pipewire 2>/dev/null; then
        _ok
    else
        _warn
    fi

    _check "pipewire-pulse"
    if systemctl --user is-active --quiet pipewire-pulse 2>/dev/null; then
        _ok
    else
        _warn
    fi

    _check "wireplumber"
    if systemctl --user is-active --quiet wireplumber 2>/dev/null; then
        _ok
    else
        _warn
    fi

    _check "pavucontrol"
    if command -v pavucontrol >/dev/null 2>&1; then
        _ok
    else
        _warn
    fi
}

validate_dotfiles() {
    echo ""
    echo "===== Dotfiles ====="

    _check ".zshrc"
    if [ -L "${HOME}/.zshrc" ] || [ -f "${HOME}/.zshrc" ]; then
        _ok
    else
        _warn
    fi

    _check ".config/nvim"
    if [ -L "${HOME}/.config/nvim" ] || [ -d "${HOME}/.config/nvim" ]; then
        _ok
    else
        _warn
    fi

    _check ".config/alacritty"
    if [ -L "${HOME}/.config/alacritty" ] || [ -d "${HOME}/.config/alacritty" ]; then
        _ok
    else
        _warn
    fi

    _check "Lazy.nvim"
    if [ -d "${HOME}/.local/share/nvim/site/pack/lazy/start/lazy.nvim" ]; then
        _ok
    else
        _warn
    fi
}

validate_shell() {
    echo ""
    echo "===== Shell Configuration ====="

    _check "Default shell"
    local current_shell=$(basename "$SHELL")
    echo "$current_shell"
    if [ "$current_shell" = "zsh" ]; then
        echo "  ✓ ZSH is default"
    else
        echo "  ⚠ Current: $current_shell (run 'chsh -s $(which zsh)')"
    fi
}

validate_github() {
    echo ""
    echo "===== GitHub ====="

    _check "gh CLI"
    if command -v gh >/dev/null 2>&1; then
        _ok
        echo "  Version: $(gh --version | head -1)"

        _check "gh authentication"
        if gh auth status >/dev/null 2>&1; then
            _ok
        else
            _warn
        fi
    else
        _warn
    fi

    _check "SSH keys"
    if [ -f "${HOME}/.ssh/id_ed25519" ] || [ -f "${HOME}/.ssh/id_rsa" ]; then
        _ok
    else
        _warn
    fi
}

system_info() {
    echo ""
    echo "===== System Information ====="
    echo "OS: $(uname -s)"
    echo "Kernel: $(uname -r)"
    echo "Architecture: $(uname -m)"

    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "Distribution: $PRETTY_NAME"
    fi

    echo "Hostname: $(hostname)"
    echo "User: $USER"
}

main() {
    echo "╔══════════════════════════════════════════════╗"
    echo "║                                              ║"
    echo "║     Dotfiles Installation Validator          ║"
    echo "║                                              ║"
    echo "╚══════════════════════════════════════════════╝"

    system_info
    validate_core_tools
    validate_rust_tools
    validate_nodejs
    validate_docker
    validate_window_manager
    validate_audio
    validate_dotfiles
    validate_shell
    validate_github

    echo ""
    echo "================================"
    echo "Validation complete!"
    echo "✓ = Installed and working"
    echo "⚠ = Not installed or not working"
    echo "================================"
}

main "$@"
