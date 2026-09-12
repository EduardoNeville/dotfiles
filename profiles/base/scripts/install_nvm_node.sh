#!/usr/bin/env bash
# Install NVM (node version manager) + Node LTS + bun (JS package manager).
# Global JS packages install via `bun add -g` — never npm (preference 2026-09).
# Non-interactive + idempotent: safe under install.sh (no prompts).

set -eo pipefail # no -u: nvm.sh reads unset variables internally
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"

_process() { echo "$(tput setaf 6)→ $1...$(tput sgr0)"; }
_success() { echo "$(tput setaf 2)✓ Success:$(tput sgr0) $1"; }
_error() { echo "$(tput setaf 1)✗ Error:$(tput sgr0) $1"; }

has() { command -v "$1" >/dev/null 2>&1; }

load_nvm() {
    export NVM_DIR="${HOME}/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
}

bootstrap_nvm() {
    _process "Installing NVM (Node Version Manager)"
    if [ -d "${HOME}/.nvm" ]; then
        _success "NVM already installed"
        load_nvm
        return 0
    fi
    local NVM_VERSION="v0.40.1"
    # PROFILE=/dev/null: we source nvm from the repo zshrc, not from the
    # installer's rc-append (which would dirty the linked dotfile).
    PROFILE=/dev/null curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash
    load_nvm
    _success "NVM installed"
}

bootstrap_node() {
    _process "Installing Node.js (latest LTS, default)"
    load_nvm
    if nvm ls 2>/dev/null | grep -q "->"; then
        _success "Node already active ($(nvm current))"
        return 0
    fi
    nvm install --lts
    nvm use --lts
    nvm alias default 'lts/*'
    _success "Node LTS installed"
}

bootstrap_bun() {
    _process "Installing bun (JS package manager)"
    if has bun; then
        _success "bun already installed ($(bun --version 2>/dev/null))"
        return 0
    fi
    curl -fsSL https://bun.sh/install | bash
    export BUN_INSTALL="${HOME}/.bun"
    export PATH="${BUN_INSTALL}/bin:${PATH}"
    _success "bun installed"
}

install_js_packages() {
    _process "Installing global JS packages via bun (one call)"
    export BUN_INSTALL="${HOME}/.bun"
    export PATH="${BUN_INSTALL}/bin:${PATH}"

    # Core set + opt/nodePkgs (the declared list), deduped, batched.
    local pkgs=(
        "@anthropic-ai/claude-code"
        "@earendil-works/pi-coding-agent"
        "@earendil-works/pi-ai"
        "typescript"
        "ts-node"
        "yarn"
        "pnpm"
    )
    if [ -f "${DOTFILES_DIR}/opt/nodePkgs" ]; then
        while read -r p; do
            [ -n "$p" ] && case "$p" in \#*) ;; *) pkgs+=("$p") ;; esac
        done <"${DOTFILES_DIR}/opt/nodePkgs"
    fi
    local unique=()
    local p
    for p in "${pkgs[@]}"; do
        case " ${unique[*]} " in *" $p "*) ;; *) unique+=("$p") ;; esac
    done

    if ! bun add -g "${unique[@]}"; then
        _error "bun batch failed — falling back per package:"
        local failed=0
        for p in "${unique[@]}"; do
            bun add -g "$p" || { _error "failed: $p"; failed=1; }
        done
        [ $failed -eq 0 ] || { _error "some JS packages failed — see names above"; return 1; }
    fi
    _success "Global JS packages installed"
}

main() {
    bootstrap_nvm
    bootstrap_node
    bootstrap_bun
    install_js_packages
    _success "Node/bun setup complete"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
