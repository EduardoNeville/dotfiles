#!/usr/bin/env bash
# update.sh — update source, then rebuild + reinstall one or all packages.
#
# Usage:
#   ./scripts/update.sh            # update ALL packages (dep order)
#   ./scripts/update.sh tmux       # update one package (+ its deps)
#   ./scripts/update.sh --no-link tmux
#
#   git     packages : git pull --ff-only, rebuild, reinstall
#   tarball packages : re-extract a pristine source dir, reconfigure, build, install
#
# For a tarball version bump: edit packages/<name>.conf (new pkg_version,
# pkg_src_dir, pkg_url, pkg_tarball), then run update.sh <name>.

set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$DIR/common.sh"

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

update_one() {
  local name="$1"
  if [ "${BUILT[$name]:-0}" = "1" ]; then return; fi
  local conf="$PKGS_ROOT/packages/$name.conf"
  [ -f "$conf" ] || die "unknown package '$name' (no $conf)"

  unset_pkg_vars
  # shellcheck disable=SC1090
  source "$conf"
  # guard against empty-array "${arr[@]:-}" producing one empty element
  if (( ${#pkg_deps[@]} > 0 )); then
    for dep in "${pkg_deps[@]}"; do
      update_one "$dep"
    done
  fi

  # Re-source so pkg_* reflect THIS package again — the dep loop above
  # re-sourced other .conf files and would otherwise leave stale values
  # (e.g. tmux's update would act on bison's src dir).
  unset_pkg_vars
  # shellcheck disable=SC1090
  source "$conf"

  case "$pkg_type" in
    git)
      log "Updating git source $pkg_name (${pkg_branch:-master})"
      cd "$PKGS_ROOT/src/$pkg_src_dir"
      git fetch origin --tags --force
      git checkout "${pkg_branch:-master}"
      if git branch -r | grep -qE "origin/${pkg_branch:-master}$"; then
        # remote branch: fast-forward
        git reset --hard "origin/${pkg_branch:-master}" \
          || die "$pkg_name: fast-forward failed (local changes?)"
      else
        # tag pin: move to the tag exactly
        git reset --hard "${pkg_branch:-master}" \
          || die "$pkg_name: reset to ${pkg_branch:-master} failed"
      fi
      ;;
    tarball)
      log "Refreshing tarball source $pkg_name"
      rm -rf "$PKGS_ROOT/src/$pkg_src_dir"
      ensure_tarball   # re-download + verify sha256 + re-extract pristine source
      ;;
    *) die "$pkg_name: unknown pkg_type '$pkg_type'" ;;
  esac
  unset_pkg_vars

  build_package "$conf"
  BUILT["$name"]=1
}

if [ "${#targets[@]}" -eq 0 ]; then
  log "Updating ALL packages"
  for name in $(all_pkg_names); do
    update_one "$name"
  done
else
  for name in "${targets[@]}"; do
    update_one "$name"
  done
fi

log "Done."
