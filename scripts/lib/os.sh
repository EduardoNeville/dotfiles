#!/usr/bin/env bash
# scripts/lib/os.sh — OS detection + package dispatcher (portable, no sudo assumptions)

_process() { echo "$(tput setaf 6)→ $1...$(tput sgr0)"; }
_success() { echo "$(tput setaf 2)✓ Success:$(tput sgr0) $1"; }
_error() { echo "$(tput setaf 1)✗ Error:$(tput sgr0) $1"; }
_prompt() { echo "$(tput setaf 3)? $1$(tput sgr0)"; }

detect_os() {
    if [ -f /etc/os-release ]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        OS="$ID"
    elif [ "$(uname)" = "Darwin" ]; then
        OS="macos"
    else
        OS="unknown"
    fi

    case "$OS" in
    ubuntu | debian) PKG="apt" ;;
    fedora | centos | rhel) PKG="dnf" ;;
    arch | manjaro) PKG="pacman" ;;
    void) PKG="xbps" ;;
    macos) PKG="brew" ;;
    *) PKG="unknown" ;;
    esac
}

HOST="$(hostname 2>/dev/null || echo unknown)"

# detect_profile — which profiles this machine activates.
# Order: $PROFILE env/--profile flag > hosts/<hostname>/PROFILE (dir style)
# or hosts/<hostname> file (legacy) > default "base".
detect_profile() {
    PROFILES="${PROFILE:-}"
    if [ -z "$PROFILES" ] && [ -f "${DOTFILES_DIR}/hosts/${HOST}/PROFILE" ]; then
        PROFILES="$(sed "s/^PROFILE=//" "${DOTFILES_DIR}/hosts/${HOST}/PROFILE" | tr -d '"')"
    elif [ -z "$PROFILES" ] && [ -f "${DOTFILES_DIR}/hosts/${HOST}" ]; then
        PROFILES="$(grep '^PROFILE=' "${DOTFILES_DIR}/hosts/${HOST}" | head -1 | cut -d= -f2- | tr -d '"')"
    fi
    PROFILES="${PROFILES:-base}"
    _process "Profiles: $PROFILES ($OS / $PKG)"

    # Record the active profiles so runtime shell configs can branch on them
    # (e.g. ~/.zprofile auto-starts X only on "desktop" machines).
    mkdir -p "${XDG_CONFIG_HOME:-${HOME}/.config}"
    printf '%s\n' "$PROFILES" > "${XDG_CONFIG_HOME:-${HOME}/.config}/dotfiles-profile"
}

has() { command -v "$1" >/dev/null 2>&1; }

# --- source-built tools (opt/source) ---------------------------------------
# Presence on PATH is NOT proof that a tool is the pinned source build.
# /usr/bin/tmux (3.5a) and a stale ~/.local/bin/nvim both satisfy `has`, which
# is how ensure_source_pkgs() ended up printing "present" forever and never
# building the manifest pin. These helpers answer the question that matters.

# Version banner of a tool: first line of its version output. Manifests whose
# tool needs a nonstandard flag declare `pkg_version_args` — tmux takes -V,
# since `tmux --version` just prints usage.
pkg_version_of() {
    local bin="$1"
    shift || true
    local args=("$@")
    [ "${#args[@]}" -gt 0 ] || args=(--version)
    "$bin" "${args[@]}" 2>/dev/null | head -1 || true
}

# source_pkg_current <bin> <want-version> [version-args...]
# 0 only when <bin> resolves INTO $HOME/pkgs/builds and reports <want-version>.
# Empty <want-version> means "any version, as long as it is our build".
source_pkg_current() {
    local bin="$1" want="$2"
    shift 2 2>/dev/null || true
    local real got
    has "$bin" || return 1
    real="$(readlink -f "$(command -v "$bin")" 2>/dev/null)" || return 1
    case "$real" in
    "${HOME}/pkgs/builds/"*) ;;
    *) return 1 ;; # system or distro build — not ours, so not the pin
    esac
    [ -n "$want" ] || return 0
    got="$(pkg_version_of "$bin" "$@")"
    case "$got" in
    *"$want"*) return 0 ;;
    *"${want#v}"*) return 0 ;; # nvim prints "NVIM v0.12.5", pin is "v0.12.5"
    esac
    return 1
}

# pkg_install <name> — install one package with the native package manager.
pkg_install() {
    case "$PKG" in
    brew) brew install "$1" ;;
    apt) sudo apt-get install -y "$1" ;;
    dnf) sudo dnf install -y "$1" ;;
    pacman) sudo pacman -S --noconfirm "$1" ;;
    xbps) sudo xbps-install -y "$1" ;;
    *)
        _error "Unknown package manager: $PKG"
        return 1
        ;;
    esac
}