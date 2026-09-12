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
    [ -d "${DOTFILES_DIR}/opt/source/packages" ] || return 0
    _process "Ensuring source-built tools (opt/source)"
    # Sync manifests into the per-machine build root — build.sh dies on
    # .conf files it can't find (it reads $PKGS_ROOT/packages/<name>.conf).
    mkdir -p "${HOME}/pkgs/packages"
    cp -f "${DOTFILES_DIR}"/opt/source/packages/*.conf "${HOME}/pkgs/packages/"
    local conf bin
    for conf in "${DOTFILES_DIR}"/opt/source/packages/*.conf; do
        [ -f "$conf" ] || continue
        bin=""
        pkg_profiles=""
        # shellcheck disable=SC1090
        source "$conf"
        # Optional per-conf profile gate (e.g. pkg_profiles="desktop"):
        # desktop-only builds need X11 headers the base profile doesn't ship.
        if [ -n "$pkg_profiles" ] && ! has_profile "$pkg_profiles"; then
            echo "  ⊘ $pkg_name (profiles: $pkg_profiles — not active here)"
            continue
        fi
        if [ -n "$pkg_bin" ] && ! has "$pkg_bin"; then
            _process "Building $pkg_name from source (missing $pkg_bin)"
            # HOME_BIN=~/.local/bin: built bins land somewhere already on PATH.
            PKGS_ROOT="${HOME}/pkgs" HOME_BIN="${HOME}/.local/bin" \
                bash "${DOTFILES_DIR}/opt/source/scripts/build.sh" "$pkg_name"
        else
            echo "  ✓ $pkg_name ($(has "$pkg_bin" && echo present))"
        fi
    done
    _success "Source packages ensured"
}

install_console_tty_setup() {
    # One TTY session, no accidental switches:
    # 1. Disable Alt+Left/Right VT cycling on the console (kernel keymap
    #    defaults Decr_Console/Incr_Console — too easy to hit in a shell).
    #    Ctrl+Alt+Fn switching is untouched; X/dwm unaffected (MODKEY=Mod4).
    # 2. Mask getty@tty2..6 — tty1 is the only TTY. getty-static respawns
    #    the idle instances unless masked.
    [ -f /etc/console/vt-no-arrow-cycle.kmap ] || {
        sudo mkdir -p /etc/console
        sudo tee /etc/console/vt-no-arrow-cycle.kmap > /dev/null <<'KMAP'
alt keycode 105 = VoidSymbol
alt keycode 106 = VoidSymbol
KMAP
    }
    if [ ! -f /etc/systemd/system/loadkeymap.service ]; then
        sudo tee /etc/systemd/system/loadkeymap.service > /dev/null <<'UNIT'
[Unit]
Description=Console keymap: disable Alt+arrow VT cycling
After=console-setup.service
[Service]
Type=oneshot
ExecStart=/usr/bin/loadkeys /etc/console/vt-no-arrow-cycle.kmap
RemainAfterExit=yes
[Install]
WantedBy=multi-user.target
UNIT
    fi
    sudo systemctl daemon-reload
    sudo systemctl enable --now loadkeymap.service
    local i
    for i in 2 3 4 5 6; do
        sudo systemctl mask "getty@tty$i.service"
    done
}

main() {
    detect_os
    detect_profile
    _process "Configuring system (Debian, profiles: $PROFILES)"

    link_dotfiles
    # Manual-auth steps are best-effort ON PURPOSE (SSH key registration and
    # dotpi access to the private repo happen once, outside install).
    bash "${DOTFILES_DIR}/profiles/base/scripts/setup_github.sh" || true
    ensure_dotpi || true
    link_gitconfig || true

    # Everything below is FAIL-FAST: each step depends on the previous ones
    # (apt layer → toolchains → source builds), so a failure stops the install
    # right where it happened instead of cascading into a confusing error later.
    link_zsh_config
    link_pi_config || true # pi config completes once the SSH key is registered; re-run install.sh
    setup_zsh_as_default
    install_zsh_plugins

    # Toolchains (Tier 5) — scripts are internally idempotent (rustc/nvm guards
    # inside), so run unconditionally: a machine with rustc but missing cargo
    # packages (opt/cargoPkgs) still gets the declared tools.
    bash "${DOTFILES_DIR}/profiles/base/scripts/install_rust_tools.sh"
    bash "${DOTFILES_DIR}/profiles/base/scripts/install_nvm_node.sh"

    if has_profile desktop; then
        [ -f "${DOTFILES_DIR}/profiles/desktop/scripts/build_suckless.sh" ] &&
            bash "${DOTFILES_DIR}/profiles/desktop/scripts/build_suckless.sh"
        [ -f "${DOTFILES_DIR}/profiles/desktop/scripts/setup_audio.sh" ] &&
            bash "${DOTFILES_DIR}/profiles/desktop/scripts/setup_audio.sh"
        [ -f "${DOTFILES_DIR}/profiles/desktop/scripts/install_wezterm.sh" ] &&
            bash "${DOTFILES_DIR}/profiles/desktop/scripts/install_wezterm.sh"
    fi

    add_user_to_groups
    setup_fonts
    install_console_tty_setup
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
