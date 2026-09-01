#!/usr/bin/env bash
# Author: Eduardo Neville <eduardoneville82@gmail.com>
# Description: Debian adapter — Linux-only system setup.
# All config linking lives in the shared engine: scripts/lib/link.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=../lib/link.sh
source "${SCRIPT_DIR}/../lib/link.sh"

add_user_to_groups() {
    _process "Adding user to necessary groups"

    local groups=("video" "audio" "input" "docker" "storage")

    for group in "${groups[@]}"; do
        if getent group "$group" >/dev/null; then
            if ! groups ${USER} | grep -q "$group"; then
                sudo usermod -aG "$group" ${USER}
                echo "  ✓ Added to $group"
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
    _process "Setting up systemd user services"

    local services_dir="${DOTFILES_DIR}/configs/services"

    if [ -d "$services_dir" ]; then
        mkdir -p "${HOME}/.config/systemd/user"

        for service in "$services_dir"/*.service; do
            [ -f "$service" ] || continue
            local service_name=$(basename "$service")
            ln -sf "$service" "${HOME}/.config/systemd/user/$service_name"
            echo "  ✓ Linked $service_name"
        done

        systemctl --user daemon-reload
        _success "Systemd user services configured"
    fi
}

main() {
    _process "Configuring system (Debian)"

    # Engine: link all configs (shared, identical on every OS)
    link_all

    # Debian-specific system configuration
    add_user_to_groups
    setup_fonts
    setup_systemd_user_services

    _success "System configuration complete (Debian)"

    echo ""
    echo "NOTE: Log out and log back in for all changes to take effect"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
