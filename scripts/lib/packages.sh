#!/usr/bin/env bash
# scripts/lib/packages.sh — cross-platform package installation.
# opt/common.txt holds tools whose names are identical on every package manager.
# Per-OS extras stay in their existing lists (opt/Brewfile, opt/debianPkgs).

install_common_packages() {
    local list="${DOTFILES_DIR}/opt/common.txt"
    [ -f "$list" ] || {
        _error "common.txt not found at $list"
        return 1
    }

    _process "Installing common packages ($PKG)"
    local failed=()
    while read -r pkg; do
        [ -z "$pkg" ] && continue
        case "$pkg" in \#*) continue ;; esac
        if pkg_install "$pkg"; then
            _success "Installed: $pkg"
        else
            _error "Failed: $pkg"
            failed+=("$pkg")
        fi
    done <"$list"

    if [ "${#failed[@]}" -gt 0 ]; then
        _error "Failed packages: ${failed[*]}"
        return 1
    fi
    _success "Common packages installed"
}
