#!/usr/bin/env bash
# scripts/debian/configure_system.sh — Debian adapter (profile-aware).
# Everything here runs on full installs; guards keep it idempotent.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/os.sh"
source "${SCRIPT_DIR}/../lib/link.sh"

has_profile() { case " $PROFILES " in *" $1 "*) return 0 ;; *) return 1 ;; esac; }

add_user_to_groups() {
    _process "Adding user to necessary groups"
    local groups=(video audio input docker storage)
    for group in "${groups[@]}"; do
        if getent group "$group" >/dev/null 2>&1; then
            if ! groups "${USER}" | grep -q "$group"; then
                sudo usermod -aG "$group" "${USER}" && echo "  ✓ Added to $group"
            fi
        fi
    done
    _success "User groups configured"
}

setup_fonts() {
    if ! has fc-cache; then
        _process "Skipping font cache (fontconfig not installed)"
        return 0
    fi
    _process "Updating font cache"
    fc-cache -fv >/dev/null 2>&1
    _success "Font cache updated"
}

setup_systemd_user_services() {
    # Base units (review timer) + desktop units (pipewire etc.).
    local services_dir
    _process "Setting up systemd user services"
    mkdir -p "${HOME}/.config/systemd/user"
    for services_dir in "${DOTFILES_DIR}/profiles/base/services" "${DOTFILES_DIR}/profiles/desktop/configs/services"; do
        [ -d "$services_dir" ] || continue
        for unit in "$services_dir"/*; do
            [ -f "$unit" ] || continue
            ln -sf "$unit" "${HOME}/.config/systemd/user/$(basename "$unit")"
            echo "  ✓ Linked $(basename "$unit")"
        done
    done
    systemctl --user daemon-reload
    # Weekly review timer (idempotent, no sudo)
    if [ -f "${HOME}/.config/systemd/user/review-packages.timer" ]; then
        systemctl --user enable review-packages.timer 2>/dev/null && echo "  ✓ enabled review-packages.timer"
    fi
    _success "Systemd user services configured"
}

ensure_source_pkgs() {
    # Tier 4: opt/source manifests; builds live in $HOME/pkgs (gitignored).
    # Presence is judged against ~/pkgs/bin (not PATH — that dir isn't on
    # PATH inside the install session; zshrc adds it for login shells).
    [ -d "${DOTFILES_DIR}/opt/source/packages" ] || return 0
    _process "Ensuring source-built tools (opt/source)"
    local conf bin
    for conf in "${DOTFILES_DIR}"/opt/source/packages/*.conf; do
        [ -f "$conf" ] || continue
        # shellcheck disable=SC1090
        source "$conf"
        [ -n "$pkg_bin" ] || continue
        if [ -x "${HOME}/pkgs/bin/${pkg_bin}" ]; then
            echo "  ✓ $pkg_name ($pkg_bin)"
        else
            _process "Building $pkg_name from source (missing $pkg_bin)"
            PKGS_ROOT="${HOME}/pkgs" bash "${DOTFILES_DIR}/opt/source/scripts/build.sh" "$pkg_name" || \
                _error "$pkg_name build failed — see output; deps: gettext/cmake/ninja/gcc (base list)"
        fi
    done
    _success "Source packages ensured"
}

main() {
    detect_os
    detect_profile
    _process "Configuring system (Debian, profiles: $PROFILES)"

    link_dotfiles
    # GitHub identity/key/gh-auth before dotpi clone (private repo needs the key)
    bash "${DOTFILES_DIR}/profiles/base/scripts/setup_github.sh" || true
    ensure_dotpi || true
    link_gitconfig || true
    link_zsh_config || true
    link_pi_config || true
    setup_zsh_as_default || true
    install_zsh_plugins || true

    # Toolchains (Tier 5) — idempotent guards
    if ! has rustc && [ -f "${DOTFILES_DIR}/profiles/base/scripts/install_rust_tools.sh" ]; then
        bash "${DOTFILES_DIR}/profiles/base/scripts/install_rust_tools.sh" || true
    fi
    if ! has fnm && ! has nvm && [ -f "${DOTFILES_DIR}/profiles/base/scripts/install_nvm_node.sh" ]; then
        bash "${DOTFILES_DIR}/profiles/base/scripts/install_nvm_node.sh" || true
    fi

    if has_profile desktop; then
        [ -f "${DOTFILES_DIR}/profiles/desktop/scripts/build_suckless.sh" ] &&
            bash "${DOTFILES_DIR}/profiles/desktop/scripts/build_suckless.sh" || true
        [ -f "${DOTFILES_DIR}/profiles/desktop/scripts/setup_audio.sh" ] &&
            bash "${DOTFILES_DIR}/profiles/desktop/scripts/setup_audio.sh" || true
        [ -f "${DOTFILES_DIR}/profiles/desktop/scripts/install_wezterm.sh" ] &&
            bash "${DOTFILES_DIR}/profiles/desktop/scripts/install_wezterm.sh" || true
    fi

    add_user_to_groups
    setup_fonts
    setup_systemd_user_services
    ensure_source_pkgs

    _success "System configuration complete (Debian)"
    echo ""
    echo "NOTE: log out and back in for groups/shell to take effect."
    echo "One-time: run profiles/base/scripts/setup_github.sh for gh auth + SSH key."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi