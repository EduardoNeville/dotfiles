#!/usr/bin/env bash
# scripts/macos/configure_system.sh — macOS adapter.
# Engine (linking) is shared: scripts/lib/link.sh. macOS-specific extras here.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=../lib/link.sh
source "${SCRIPT_DIR}/../lib/link.sh"

main() {
    _process "Configuring system (macOS)"

    link_all

    _success "System configuration complete (macOS)"
    echo ""
    echo "NOTE: Log out and log back in for all changes to take effect"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
