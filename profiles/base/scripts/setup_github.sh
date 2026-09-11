#!/usr/bin/env bash
# Setup GitHub authentication + SSH keys. Auto-run-safe: skips everything
# when already configured; non-interactive under install.sh (no TTY).
# Manual bits (registering the pubkey on github.com) are printed, not waited on.
# Optional token: envs/api_keys/GITHUB_TOKEN.txt → gh auth login --with-token.

set -e

_process() { echo "$(tput setaf 6)→ $1...$(tput sgr0)"; }
_success() { echo "$(tput setaf 2)✓ Success:$(tput sgr0) $1"; }
_error() { echo "$(tput setaf 1)✗ Error:$(tput sgr0) $1"; }
_prompt() { echo "$(tput setaf 3)? $1$(tput sgr0)"; }

GIT_EMAIL="eduardoneville82@gmail.com"

setup_git_config() {
    # Identity lives in the linked configs/.gitconfig — no prompts needed.
    if git config --global user.name >/dev/null 2>&1 && git config --global user.email >/dev/null 2>&1; then
        _success "git identity present ($(git config --global user.name) <$(git config --global user.email)>)"
        return 0
    fi
    _process "Setting git identity (defaults)"
    git config --global user.name "EduardoNeville"
    git config --global user.email "$GIT_EMAIL"
    git config --global init.defaultBranch main
    _success "git identity set"
}

setup_ssh_key() {
    local ssh_key="${HOME}/.ssh/id_ed25519"
    if [ -f "$ssh_key" ]; then
        _success "SSH key present ($ssh_key)"
        return 0
    fi
    _process "Generating ed25519 key"
    mkdir -p "${HOME}/.ssh" && chmod 700 "${HOME}/.ssh"
    if [ -t 0 ]; then
        # interactive terminal: allow passphrase
        ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f "$ssh_key"
    else
        # ponytail: no-TTY install → empty passphrase; the key only guards
        # git pushes (add passphrase later via ssh-keygen -p if wanted)
        ssh-keygen -t ed25519 -N "" -C "$GIT_EMAIL" -f "$ssh_key"
    fi
    eval "$(ssh-agent -s)" >/dev/null 2>&1 || true
    ssh-add "$ssh_key" 2>/dev/null || true
    echo ""
    echo "====== Register this key: https://github.com/settings/ssh/new ======"
    cat "${ssh_key}.pub"
    echo "===================================================================="
    _success "SSH key generated (register the .pub above once)"
}

setup_gh_auth() {
    _process "Checking gh auth"
    if ! has_gh; then
        _error "gh not installed — install.sh installs it via the vendor repo; rerun after"
        return 1
    fi
    if gh auth status >/dev/null 2>&1; then
        _success "gh authenticated"
        return 0
    fi
    local token_file="${DOTFILES_DIR:-$HOME/dotfiles}/envs/api_keys/GITHUB_TOKEN.txt"
    if [ -f "$token_file" ]; then
        _process "gh auth via token file"
        gh auth login --with-token <"$token_file" && _success "gh authenticated (token)" && return 0
    fi
    if [ -t 0 ]; then
        _prompt "Device flow — follow the printed code:"
        gh auth login --hostname github.com --git-protocol ssh --web || true
    else
        _error "gh not authenticated (no TTY, no GITHUB_TOKEN.txt) — run profiles/base/scripts/setup_github.sh once in a terminal"
    fi
}

has_gh() { command -v gh >/dev/null 2>&1; }

main() {
    _process "GitHub Setup (auto-safe)"
    setup_git_config
    setup_ssh_key
    # SSH key must exist for git@ github clones (dotpi); gh auth is best-effort.
    setup_gh_auth || true
    _success "GitHub setup complete"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi