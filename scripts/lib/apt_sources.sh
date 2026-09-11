#!/usr/bin/env bash
# scripts/lib/apt_sources.sh — declared apt sources (deb822, one file per repo).
# Base: apt-sources/debian.sources (trixie + updates + security + backports).
# Per-host vendors: hosts/<host>/apt-sources/*.sources.
# Naming scheme: <vendor-shortname>.sources; repo basename == deployed basename.
# Strays (managed *.list / *.bak) are removed — one file per repo.

setup_apt_sources() {
    [ "$PKG" = "apt" ] || return 0
    _process "Installing apt sources (deb822)"
    local dest=/etc/apt/sources.list.d

    sudo mkdir -p "$dest"
    sudo mkdir -p /etc/apt/keyrings

    # Remove one-line/dup/bak strays of managed repos
    for f in debian github-cli redis hpe-mcp docker tailscale; do
        sudo rm -f "$dest/$f.list" "$dest/$f.list.save" "$dest/$f.list.bak"
    done

    # Base sources
    sudo cp "${DOTFILES_DIR}/apt-sources/"*.sources "$dest/"

    # Per-host vendor sources
    local host_src="${DOTFILES_DIR}/hosts/${HOST}/apt-sources"
    if [ -d "$host_src" ]; then
        sudo cp "$host_src/"*.sources "$dest/"
    fi

    bootstrap_keyring docker /etc/apt/keyrings/docker.asc https://download.docker.com/linux/debian/gpg
    bootstrap_keyring tailscale /usr/share/keyrings/tailscale-archive-keyring.gpg https://pkgs.tailscale.com/stable/debian/trixie/pubkey.gpg
    bootstrap_keyring githubcli /etc/apt/keyrings/githubcli-archive-keyring.gpg https://cli.github.com/packages/githubcli-archive-keyring.gpg


    sudo apt-get update
    _success "Apt sources installed (backports remain opt-in via opt/backports.txt)"
}

# bootstrap_keyring <name> <dest> <official-url> — fetch only when missing.
bootstrap_keyring() {
    [ -f "$2" ] && return 0
    _process "Fetching $1 keyring (official URL)"
    local tmp="/tmp/$1.keyring"
    curl -fsSL "$3" -o "$tmp" || {
        _error "keyring fetch failed for $1 — fix manually, repos will 404/NO_PUBKEY"
        return 1
    }
    sudo install -m 0644 "$tmp" "$2" && rm -f "$tmp"
}