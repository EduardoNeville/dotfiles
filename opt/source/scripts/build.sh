#!/usr/bin/env bash
# build.sh — build and install one or all packages from packages/*.conf.
#
# Usage:
#   ./scripts/build.sh                 # build+install all packages (dep order)
#   ./scripts/build.sh tmux            # build+install one package (+ its deps)
#   ./scripts/build.sh --no-link tmux  # build but don't create ~/bin symlinks
#
# Installs each package into its own prefix dir (nvim/, tmux/, ...) at the
# pkgs root, and optionally links the binaries into ~/bin.

set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$DIR/common.sh"

# Parse args: flags before an optional package name.
LINK=1
targets=()
for arg in "$@"; do
  case "$arg" in
    --no-link) LINK=0 ;;
    --) : ;;
    *) targets+=("$arg") ;;
  esac
done
export LINK

init_build_env
unset_pkg_vars

if [ "${#targets[@]}" -eq 0 ]; then
  log "Building ALL packages"
  for name in $(all_pkg_names); do
    ensure_pkg "$name"
  done
else
  for name in "${targets[@]}"; do
    ensure_pkg "$name"
  done
fi

log "Done."
