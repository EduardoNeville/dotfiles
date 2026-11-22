#!/usr/bin/env bash
# install_battery_guard.sh — repair/reinstall the root-owned battery guard on
# an existing machine.
#
#   scripts/install_battery_guard.sh
#   PROFILE=base,desktop scripts/install_battery_guard.sh
#
# This is the narrow repair path: it installs /usr/local/lib/battery-guard/
# battery_guard.sh and the battery-guard systemd units from the active
# profiles, reloads systemd, and arms the timer. It does not touch dotfile
# links, packages, user services, or the rest of the install.
#
# The full installer (./install.sh) calls the same configure_system.sh
# function, so this is only needed when repairing a machine whose units were
# installed by an older checkout (the units used to live in profiles/base and
# point at a user-owned path under /home).
#
# The unit runs as root: hibernating and writing charge_behaviour from a timer
# need root, and /home is a separate mount that systemd cannot resolve at boot.
# Hence the copies on the root filesystem. Plug in AC first if the battery is
# already at/below the 10% handover point, so the guard does not hibernate
# while you are installing.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="${DOTFILES_DIR:-$(cd "${SCRIPT_DIR}/.." && pwd)}"

if [ ! -f "${DOTFILES_DIR}/scripts/debian/configure_system.sh" ]; then
    echo "missing ${DOTFILES_DIR}/scripts/debian/configure_system.sh" >&2
    exit 1
fi

exec bash "${DOTFILES_DIR}/scripts/debian/configure_system.sh" --system-services-only
