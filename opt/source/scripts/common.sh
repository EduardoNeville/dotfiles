#!/usr/bin/env bash
# common.sh — shared helpers for the pkgs build/update scripts.
# Sourced by build.sh and update.sh. Do not run directly.

set -euo pipefail

# Root of this pkgs tree (parent of scripts/). Overridable: the dotfiles
# copy of these scripts runs against the per-machine build root via
# PKGS_ROOT=~/pkgs (gitignored), while the manifests live in opt/source.
PKGS_ROOT="${PKGS_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# Where built/installed prefixes live (tmux/, bison/, libevent/, nvim/ ...).
PREFIX_ROOT="$PKGS_ROOT/builds"
JOBS="${JOBS:-$(nproc)}"
declare -A BUILT=()

# Reset package-scoped variables before sourcing a fresh .conf so no state
# (especially the arrays) leaks from a previously sourced package.
unset_pkg_vars() {
  unset pkg_name pkg_version pkg_type pkg_src_dir pkg_url pkg_tarball \
        pkg_build pkg_prefix pkg_deps pkg_configure_args pkg_cmake_args 2>/dev/null || true
}

log()  { printf '\033[1;34m==> %s\033[0m\n' "$*"; }
info() { printf '    %s\n' "$*"; }
die()  { printf '\033[1;31mERROR: %s\033[0m\n' "$*" >&2; exit 1; }

# Download a tarball into src/ if not already present and extract its source dir.
ensure_tarball() {
  local tarball="$PKGS_ROOT/src/$pkg_tarball"
  local src_dir="$PKGS_ROOT/src/$pkg_src_dir"

  if [ ! -f "$tarball" ]; then
    log "Downloading $pkg_tarball"
    mkdir -p "$PKGS_ROOT/src"
    curl -fL "$pkg_url" -o "$tarball" || die "failed to download $pkg_url"
  fi

  if [ -n "${pkg_sha256:-}" ]; then
    echo "$pkg_sha256  $tarball" | sha256sum -c - >/dev/null 2>&1 \
      || die "$pkg_name: sha256 mismatch for $pkg_tarball (expected $pkg_sha256)"
  fi

  if [ ! -d "$src_dir" ]; then
    log "Extracting $pkg_tarball"
    tar -xzf "$tarball" -C "$PKGS_ROOT/src" || die "failed to extract $pkg_tarball"
    # Autotools tarballs extract to a dir named after the version, so if the
    # configured src_dir doesn't match, find the single extracted dir.
    if [ ! -d "$src_dir" ]; then
      local found
      found="$(find "$PKGS_ROOT/src" -maxdepth 1 -type d -newer "$tarball" | grep -v '^$' | head -1)"
      [ -n "$found" ] && mv "$found" "$src_dir"
    fi
  fi
}

# Ensure a git source exists (clone if missing).
ensure_git() {
  local src_dir="$PKGS_ROOT/src/$pkg_src_dir"
  if [ ! -d "$src_dir/.git" ]; then
    log "Cloning $pkg_name from $pkg_url"
    mkdir -p "$PKGS_ROOT/src"
    git clone --branch "${pkg_branch:-master}" "$pkg_url" "$src_dir" \
      || die "failed to clone $pkg_url"
  fi
}

# Runtime loader path for privately-built libs (e.g. tmux → our libevent):
# baked in as an rpath, so binaries stay self-contained without exporting
# LD_LIBRARY_PATH everywhere.
pkg_rpath() {
  local d out=""
  for d in "$PREFIX_ROOT"/*/lib; do
    [ -d "$d" ] && out="$d:$out"
  done
  printf '%s' "${out%:}"
}

# --- build types -----------------------------------------------------------

build_autotools() {
  ensure_tarball
  cd "$PKGS_ROOT/src/$pkg_src_dir"
  local rpath
  rpath="$(pkg_rpath)"
  [ -n "$rpath" ] && export LDFLAGS="-Wl,-rpath,$rpath ${LDFLAGS:-}"
  if [ ! -f Makefile ]; then
    log "Configuring $pkg_name (autotools)"
    if (( ${#pkg_configure_args[@]} > 0 )); then
      ./configure --prefix="$PREFIX_ROOT/$pkg_prefix" "${pkg_configure_args[@]}" \
        || die "$pkg_name configure failed"
    else
      ./configure --prefix="$PREFIX_ROOT/$pkg_prefix" \
        || die "$pkg_name configure failed"
    fi
  fi
  log "Building $pkg_name"
  make -j "$JOBS" || die "$pkg_name make failed"
  log "Installing $pkg_name -> $pkg_prefix/"
  make install || die "$pkg_name make install failed"
}

build_cmake() {
  local build_dir="build-release"
  local rpath
  rpath="$(pkg_rpath)"
  [ -n "$rpath" ] && export LDFLAGS="-Wl,-rpath,$rpath ${LDFLAGS:-}"
  if [ "$pkg_type" = "git" ]; then
    ensure_git
  else
    ensure_tarball
  fi
  cd "$PKGS_ROOT/src/$pkg_src_dir"
  log "Configuring $pkg_name (cmake)"
  if (( ${#pkg_cmake_args[@]} > 0 )); then
    cmake -B "$build_dir" -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX="$PREFIX_ROOT/$pkg_prefix" \
      -DCMAKE_INSTALL_LIBDIR=lib \
      "${pkg_cmake_args[@]}" || die "$pkg_name cmake configure failed"
  else
    cmake -B "$build_dir" -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX="$PREFIX_ROOT/$pkg_prefix" \
      -DCMAKE_INSTALL_LIBDIR=lib \
      || die "$pkg_name cmake configure failed"
  fi
  log "Building $pkg_name"
  cmake --build "$build_dir" -j "$JOBS" || die "$pkg_name build failed"
  log "Installing $pkg_name -> $pkg_prefix/"
  cmake --install "$build_dir" || die "$pkg_name install failed"
}

build_make() {
  # Package with its own top-level Makefile that orchestrates dependency +
  # main builds (e.g. neovim: deps -> build/ -> install). PREFIX is passed
  # alongside CMAKE_INSTALL_PREFIX for plain-Makefile packages (clipmenu);
  # cmake-based ones ignore it.
  if [ "$pkg_type" = "git" ]; then
    ensure_git
  else
    ensure_tarball
  fi
  cd "$PKGS_ROOT/src/$pkg_src_dir"
  log "Building $pkg_name via Makefile"
  make CMAKE_BUILD_TYPE=Release CMAKE_INSTALL_PREFIX="$PREFIX_ROOT/$pkg_prefix" \
    -j "$JOBS" || die "$pkg_name make failed"
  log "Installing $pkg_name -> $pkg_prefix/"
  make install CMAKE_INSTALL_PREFIX="$PREFIX_ROOT/$pkg_prefix" \
    PREFIX="$PREFIX_ROOT/$pkg_prefix" \
    || die "$pkg_name make install failed"
}

build_package() {
  local conf="$1"
  unset_pkg_vars
  # shellcheck disable=SC1090
  source "$conf"
  : "${pkg_name:?missing pkg_name in $conf}"
  : "${pkg_prefix:?missing pkg_prefix in $conf}"

  log "Building $pkg_name ($pkg_version) [type=$pkg_type build=$pkg_build]"
  case "$pkg_build" in
    autotools) build_autotools ;;
    cmake)     build_cmake ;;
    make)      build_make ;;
    *) die "$pkg_name: unknown build system '$pkg_build'" ;;
  esac

  [ "${LINK:-1}" = "1" ] && link_bins
}

# Optionally create symlinks for installed binaries in the pkgs activation dir
# (pkgs/bin), which is meant to be on PATH. Never overwrites an existing
# non-symlink (or different-target) entry.
link_bins() {
  local bin_dir="$PREFIX_ROOT/$pkg_prefix/bin"
  [ -d "$bin_dir" ] || return 0
  local dest_home="${HOME_BIN:-$PKGS_ROOT/bin}"
  mkdir -p "$dest_home"
  for bin in "$bin_dir"/*; do
    [ -f "$bin" ] || continue
    local name link
    name="$(basename "$bin")"
    link="$dest_home/$name"
    if [ -L "$link" ]; then
      # already linked; point it at the fresh prefix if it differs
      if [ "$(readlink -f "$link")" != "$bin" ]; then
        ln -sfn "$bin" "$link"
        info "fixed symlink $link"
      fi
    elif [ -e "$link" ]; then
      info "skip $link (exists, not a symlink)"
    else
      ln -s "$bin" "$link"
      info "linked $link -> $bin"
    fi
  done
}

# Build-time environment: expose every installed package's include/lib dirs so
# downstream packages (e.g. tmux) can link against upstream libs (e.g. libevent)
# that live in our own prefixes.
init_build_env() {
  local f prefix
  # Reset: called again after deps are built (fresh machine → dirs appear
  # mid-run), so stale/empty state from the pre-build scan must not linger.
  export CPATH="" LIBRARY_PATH="" LD_LIBRARY_PATH="" PKG_CONFIG_PATH=""
  local pathadd=""
  for f in "$PKGS_ROOT"/packages/*.conf; do
    [ -e "$f" ] || continue
    unset pkg_prefix
    # shellcheck disable=SC1090
    source "$f"
    [ -n "${pkg_prefix:-}" ] || continue
    prefix="$PREFIX_ROOT/$pkg_prefix"
    [ -d "$prefix/include" ] && CPATH="$prefix/include:$CPATH"
    if [ -d "$prefix/lib" ]; then
      LIBRARY_PATH="$prefix/lib:$LIBRARY_PATH"
      LD_LIBRARY_PATH="$prefix/lib:$LD_LIBRARY_PATH"
    fi
    [ -d "$prefix/lib/pkgconfig" ] && PKG_CONFIG_PATH="$prefix/lib/pkgconfig:$PKG_CONFIG_PATH"
    [ -d "$prefix/bin" ] && pathadd="$prefix/bin:$pathadd"
  done
  export CPATH LIBRARY_PATH LD_LIBRARY_PATH PKG_CONFIG_PATH
  # drop trailing separators / empty components
  CPATH=${CPATH%:}; LIBRARY_PATH=${LIBRARY_PATH%:}
  LD_LIBRARY_PATH=${LD_LIBRARY_PATH%:}; PKG_CONFIG_PATH=${PKG_CONFIG_PATH%:}
  export CPATH LIBRARY_PATH LD_LIBRARY_PATH PKG_CONFIG_PATH
  # make upstream tools (e.g. bison -> yacc) findable by configure scriptsc etc.
  if [ -n "$pathadd" ]; then
    PATH="$pathadd$PATH"
    export PATH
  fi
}

# Recursively build a package, ensuring its declared deps are built first.
ensure_pkg() {
  local name="$1"
  if [ "${BUILT[$name]:-0}" = "1" ]; then return; fi
  local conf="$PKGS_ROOT/packages/$name.conf"
  [ -f "$conf" ] || die "unknown package '$name' (no $conf)"

  unset_pkg_vars
  # shellcheck disable=SC1090
  source "$conf"
  # NOTE: "${arr[@]:-}" on an EMPTY array yields one empty element, so guard.
  if (( ${#pkg_deps[@]} > 0 )); then
    for dep in "${pkg_deps[@]}"; do
      ensure_pkg "$dep"
    done
  fi
  unset_pkg_vars

  # Deps are built/installed by now — refresh the build env so THIS package
  # (e.g. tmux) actually sees them (a fresh machine has empty prefixes when
  # the script starts, so the one-shot init at launch isn't enough).
  init_build_env
  build_package "$conf"
  BUILT["$name"]=1
}

# List package names from packages/*.conf in dependency order (best-effort,
# stable alphabetical within each dependency depth via recursion).
all_pkg_names() {
  local f
  for f in "$PKGS_ROOT"/packages/*.conf; do
    [ -e "$f" ] || continue
    basename "$f" .conf
  done | sort
}
