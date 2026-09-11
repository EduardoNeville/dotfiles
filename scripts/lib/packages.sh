#!/usr/bin/env bash
# scripts/lib/packages.sh — profile-driven cross-platform package install.
# Sources merged per machine (in order):
#   profiles/<p>/packages.common      — every profile, any package manager
#   profiles/<p>/packages.apt|brew    — per manager
#   hosts/<host>/packages.apt|brew    — per-host extras (HP tools, services)
# opt/backports.txt declares tier-1 backports: those install with
# `-t trixie-backports` (never implicit).

pkg_lists() { # print this machine's package list files
    local p
    for p in $PROFILES; do
        [ -f "${DOTFILES_DIR}/profiles/$p/packages.common" ] && echo "${DOTFILES_DIR}/profiles/$p/packages.common"
        [ -f "${DOTFILES_DIR}/profiles/$p/packages.$PKG" ] && echo "${DOTFILES_DIR}/profiles/$p/packages.$PKG"
    done
    [ -f "${DOTFILES_DIR}/hosts/${HOST}/packages.$PKG" ] && echo "${DOTFILES_DIR}/hosts/${HOST}/packages.$PKG"
}

declared_packages() { # non-comment names from every active list
    pkg_lists | xargs grep -hvE '^\s*(#|$)' 2>/dev/null
}

in_backports() { grep -qx "$1" "${DOTFILES_DIR}/opt/backports.txt" 2>/dev/null; }

install_one() {
    case "$PKG" in
    apt)
        if in_backports "$1"; then
            sudo apt-get install -y -t trixie-backports "$1"
        else
            sudo apt-get install -y "$1"
        fi
        ;;
    *) pkg_install "$1" ;;
    esac
}

install_profile_packages() {
    _process "Installing profile packages ($PROFILES / $PKG)"
    [ "$PKG" = "apt" ] && sudo apt-get update
    local failed=() total=0 pkg
    while read -r pkg; do
        [ -n "$pkg" ] || continue
        total=$((total + 1))
        if install_one "$pkg" >/dev/null 2>&1; then
            echo "  ✓ $pkg"
        else
            _error "Failed: $pkg"
            failed+=("$pkg")
        fi
    done < <(declared_packages | sort -u)

    if [ "${#failed[@]}" -gt 0 ]; then
        _error "Failed (${#failed[@]}): ${failed[*]}"
        return 1
    fi
    _success "$total packages installed"
}