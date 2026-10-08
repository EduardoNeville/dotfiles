#!/usr/bin/env bash
# build.sh — build and install one or all packages from packages/*.conf.
#
# Usage:
#   ./scripts/build.sh                 # build+install all packages (dep order)
#   ./scripts/build.sh tmux            # build+install one package (+ its deps)
#   ./scripts/build.sh --no-link tmux  # build but don't create symlinks
#   ./scripts/build.sh --force nvim    # wipe build dir first, so the LINK
#                                      # reruns (needed when the system
#                                      # toolchain moved; see check.sh)
#
# Installs each package into its own prefix dir (nvim/, tmux/, ...) at
# $PREFIX_ROOT, and optionally links the binaries into $HOME_BIN (~/bin).

set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$DIR/common.sh"

# Parse args: flags before an optional package name.
LINK=1
FORCE=0
targets=()
for arg in "$@"; do
  case "$arg" in
    --no-link) LINK=0 ;;
    --force) FORCE=1 ;;
    --) : ;;
    *) targets+=("$arg") ;;
  esac
done
export LINK FORCE

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

# Verify what we just installed actually loads here. A stale toolchain leaves
# binaries linked against a libc this system no longer provides; fail loudly
# with the rebuild command instead of letting it surface later as a mystery
# "version `GLIBC_2.42' not found".
"$DIR/check.sh"
log "Done."
