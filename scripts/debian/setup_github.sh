#!/usr/bin/env bash
# Author: Eduardo Neville <eduadoneville82@gmail.com>
# Description: Setup GitHub authentication and SSH keys

set -e

_process() { echo "$(tput setaf 6)→ $1...$(tput sgr0)"; }
_success() { echo "$(tput setaf 2)✓ Success:$(tput sgr0) $1"; }
_error() { echo "$(tput setaf 1)✗ Error:$(tput sgr0) $1"; }
_prompt() { echo "$(tput setaf 3)? $1$(tput sgr0)"; }

setup_github() {
    _process "Setting up GitHub authentication"

    # Check if gh CLI is installed
    if ! command -v gh >/dev/null 2>&1; then
        _error "GitHub CLI (gh) is not installed. Installing now..."

        # Install gh CLI for Debian
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
        sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
        sudo apt update
        sudo apt install -y gh

        _success "GitHub CLI installed"
    fi

    # Check if already authenticated
    if gh auth status >/dev/null 2>&1; then
        _success "Already authenticated with GitHub"
        return 0
    fi

    _prompt "GitHub authentication required. Choose method:"
    echo "1) Browser-based authentication (recommended)"
    echo "2) Token authentication"
    echo "3) SSH key setup"
    read -p "Select (1-3): " auth_choice

    case $auth_choice in
        1)
            _process "Authenticating via browser"
            gh auth login -p https -w
            ;;
        2)
            _process "Authenticating via token"
            gh auth login -p https
            ;;
        3)
            setup_ssh_key
            ;;
        *)
            _error "Invalid choice. Defaulting to browser authentication"
            gh auth login -p https -w
            ;;
    esac

    _success "GitHub authentication complete"
}

setup_ssh_key() {
    _process "Setting up SSH key for GitHub"

    local email
    read -p "Enter your GitHub email: " email

    local ssh_key="${HOME}/.ssh/id_ed25519"

    if [ -f "$ssh_key" ]; then
        _prompt "SSH key already exists. Use existing key? (y/n)"
        read -p "> " use_existing
        if [[ ! "$use_existing" =~ ^[Yy]$ ]]; then
            ssh_key="${HOME}/.ssh/id_ed25519_github_$(date +%Y%m%d)"
            _process "Creating new SSH key at $ssh_key"
            ssh-keygen -t ed25519 -C "$email" -f "$ssh_key"
        fi
    else
        _process "Generating new SSH key"
        ssh-keygen -t ed25519 -C "$email" -f "$ssh_key"
    fi

    # Start ssh-agent and add key
    eval "$(ssh-agent -s)"
    ssh-add "$ssh_key"

    # Copy public key to clipboard if possible
    if command -v xclip >/dev/null 2>&1; then
        cat "${ssh_key}.pub" | xclip -selection clipboard
        _success "Public key copied to clipboard"
    elif command -v wl-copy >/dev/null 2>&1; then
        cat "${ssh_key}.pub" | wl-copy
        _success "Public key copied to clipboard"
    else
        echo ""
        echo "====== Your SSH Public Key ======"
        cat "${ssh_key}.pub"
        echo "================================="
        echo ""
    fi

    _prompt "Add this SSH key to your GitHub account:"
    echo "1. Go to https://github.com/settings/keys"
    echo "2. Click 'New SSH key'"
    echo "3. Paste the key and save"
    read -p "Press Enter when done..."

    # Test SSH connection
    _process "Testing SSH connection to GitHub"
    if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
        _success "SSH authentication successful"
    else
        _error "SSH authentication failed. Please check your setup"
    fi
}

setup_git_config() {
    _process "Configuring git"

    # Check if .gitconfig already has user info
    if git config --global user.name >/dev/null 2>&1 && git config --global user.email >/dev/null 2>&1; then
        local current_name=$(git config --global user.name)
        local current_email=$(git config --global user.email)
        _prompt "Current git config: $current_name <$current_email>"
        read -p "Keep current configuration? (y/n): " keep_config
        if [[ "$keep_config" =~ ^[Yy]$ ]]; then
            _success "Keeping existing git configuration"
            return 0
        fi
    fi

    read -p "Enter your name for git commits: " git_name
    read -p "Enter your email for git commits: " git_email

    git config --global user.name "$git_name"
    git config --global user.email "$git_email"

    # Set up default branch name
    git config --global init.defaultBranch main

    # Use delta as pager if available
    if command -v delta >/dev/null 2>&1; then
        git config --global core.pager delta
        git config --global interactive.diffFilter "delta --color-only"
        git config --global delta.navigate true
        git config --global delta.dark true
        git config --global merge.conflictstyle zdiff3
    fi

    _success "Git configuration complete"
}

main() {
    _process "GitHub Setup"
    setup_git_config
    setup_github
    _success "GitHub setup complete"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
