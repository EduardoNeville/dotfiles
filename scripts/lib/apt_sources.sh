#!/usr/bin/env bash
# scripts/lib/apt_sources.sh — declared apt sources (deb822, one file per repo).

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"

# Base: apt-sources/debian.sources (trixie + updates + security + backports).
# Per-host vendors: hosts/<host>/apt-sources/*.sources.
# Naming scheme: <vendor-shortname>.sources; repo basename == deployed basename.
# Strays (one-line *.list / *.bak) are removed — one file per repo. The stock
# root sources.list is retired to a timestamped backup once deb822 takes over,
# otherwise its one-line entries duplicate debian.sources ("configured multiple
# times" warnings) and any legacy vendored lines (old docker.list etc.) linger.

setup_apt_sources() {
    [ "$PKG" = "apt" ] || return 0
    _process "Installing apt sources (deb822)"
    local dest=/etc/apt/sources.list.d

    sudo mkdir -p "$dest"
    sudo mkdir -p /etc/apt/keyrings

    # Retire the stock one-line sources.list: debian.sources below covers the
    # same trixie/updates/security suites. Keep a timestamped backup, matching
    # the install-wide backup-then-link convention.
    if [ -e /etc/apt/sources.list ] && [ ! -L /etc/apt/sources.list ]; then
        sudo mv /etc/apt/sources.list "/etc/apt/sources.list.backup.$(date +%Y%m%d_%H%M%S)"
    fi

    # Remove one-line/dup/bak strays of managed repos
    for f in debian github-cli redis hpe-mcp docker tailscale google-chrome pgdg; do
        sudo rm -f "$dest/$f.list" "$dest/$f.list.save" "$dest/$f.list.bak"
    done

    # Base sources
    sudo cp "${DOTFILES_DIR}/apt-sources/"*.sources "$dest/"

    # Per-host vendor sources
    local host_src="${DOTFILES_DIR}/hosts/${HOST}/apt-sources"
    if [ -d "$host_src" ]; then
        sudo cp "$host_src/"*.sources "$dest/"
    fi

    # Keyrings are re-fetched every run: they're tiny, and a cached keyring
    # can outlive upstream key rotation (docker's rotated key) → EXPKEYSIG /
    # NO_PUBKEY on apt-get update.
    bootstrap_keyring docker /etc/apt/keyrings/docker.asc https://download.docker.com/linux/debian/gpg
    bootstrap_keyring tailscale /usr/share/keyrings/tailscale-archive-keyring.gpg https://pkgs.tailscale.com/stable/debian/trixie.noarmor.gpg
    bootstrap_keyring githubcli /etc/apt/keyrings/githubcli-archive-keyring.gpg https://cli.github.com/packages/githubcli-archive-keyring.gpg

    sudo apt-get update
    _success "Apt sources installed (backports remain opt-in via opt/backports.txt)"
}

# bootstrap_keyring <name> <dest> <official-url> — (re)fetch the official keyring.
bootstrap_keyring() {
    _process "Fetching $1 keyring (official URL)"
    local tmp="/tmp/$1.keyring"
    curl -fsSL "$3" -o "$tmp" || {
        _error "keyring fetch failed for $1 — fix manually, repos will 404/NO_PUBKEY"
        return 1
    }
    sudo install -m 0644 "$tmp" "$2" && rm -f "$tmp"
}