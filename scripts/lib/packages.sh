#!/usr/bin/env bash
# scripts/lib/packages.sh — profile-driven cross-platform package install.
# Sources merged per machine (in order):
#   profiles/<p>/packages.common      — every profile, any package manager
#   profiles/<p>/packages.apt|brew    — per manager
#   hosts/<host>/packages.apt|brew    — per-host extras (HP tools, services)
# opt/backports.txt declares tier-1 backports: those install with
# `-t trixie-backports` (never implicit).
#
# Batching: one package-manager call per bucket (apt downloads in parallel,
# single dpkg transaction) — never one call per package. Failures surface
# with output; "Unable to locate" names are dropped and the rest retried once.

pkg_lists() { # print this machine's package list files
    local p
    for p in $PROFILES; do
        [ -f "${DOTFILES_DIR}/profiles/$p/packages.common" ] && echo "${DOTFILES_DIR}/profiles/$p/packages.common"
        [ -f "${DOTFILES_DIR}/profiles/$p/packages.$PKG" ] && echo "${DOTFILES_DIR}/profiles/$p/packages.$PKG"
    done
    [ -f "${DOTFILES_DIR}/hosts/${HOST}/packages.$PKG" ] && echo "${DOTFILES_DIR}/hosts/${HOST}/packages.$PKG"
}

declared_packages() { # non-comment names from every active list
    pkg_lists | xargs grep -hvE '^\s*(#|$)' 2>/dev/null
}

in_backports() { grep -qx "$1" "${DOTFILES_DIR}/opt/backports.txt" 2>/dev/null; }

# apt_batch <main|backports> <pkgs...> — ONE apt-get call (+ retry pass).
# Streams live output (a 2GB texlive batch otherwise looks hung for 15 min),
# noninteractive (no debconf stalls), retries flaky downloads, keeps the
# user's config files on package upgrades.
apt_batch() {
    local tag="$1"; shift
    local pkgs=("$@")
    [ ${#pkgs[@]} -gt 0 ] || return 0
    local tflag=()
    [ "$tag" = "backports" ] && tflag=(-t trixie-backports)
    local log=/tmp/apt-batch-$tag.log

    _process "Installing ${#pkgs[@]} packages ($tag) — single apt call (live progress below)"
    sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y \
        -o Acquire::Retries=3 \
        -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold \
        "${tflag[@]}" "${pkgs[@]}" 2>&1 | sudo tee "$log"
    local rc=${PIPESTATUS[0]}
    if [ $rc -eq 0 ]; then
        grep -E "upgraded|newly installed|not upgraded" "$log" | sed 's/^/    /'
        return 0
    fi

    # Apt failed: drop unresolvable names, retry the rest once, then report.
    local bad
    bad="$(sed -n 's/.*Unable to locate package \([^ ]*\).*/\1/p' "$log" | sort -u)"
    local retry=() p
    for p in "${pkgs[@]}"; do
        if printf '%s\n' "$bad" | grep -qx "$p"; then
            _error "package not found in $PKG repos: $p (dropped — wrong name? missing vendor repo?)"
        else
            retry+=("$p")
        fi
    done
    if [ ${#retry[@]} -gt 0 ]; then
        _process "Retrying ${#retry[@]} packages (first pass exited $rc)"
        sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y \
            -o Acquire::Retries=3 \
            -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold \
            "${tflag[@]}" "${retry[@]}" 2>&1 | sudo tee "$log"
        rc=${PIPESTATUS[0]}
        [ $rc -eq 0 ] && grep -E "upgraded|newly installed|not upgraded" "$log" | sed 's/^/    /'
    fi
    if [ $rc -ne 0 ]; then
        _error "apt still failing; last output:"
        tail -15 "$log" | sed 's/^/    /'
        return 1
    fi
    # A retry that succeeded while dropping bad names is STILL a failure: the
    # caller must stop so the missing packages get attention (e.g. a dropped
    # docker-ce leaves no runtime and a confusing next-step error).
    if [ -n "$bad" ]; then
        _error "apt installed the resolvable packages but dropped: $(printf '%s' "$bad" | tr '\n' ' ')"
        return 1
    fi
    return 0
}

# brew_batch <pkgs...> — ONE brew call; on failure, isolate bad formulae.
brew_batch() {
    local pkgs=("$@")
    [ ${#pkgs[@]} -gt 0 ] || return 0
    _process "Installing ${#pkgs[@]} formulae — single brew call"
    local out rc=0
    out="$(brew install "${pkgs[@]}" 2>&1)" || rc=$?
    [ $rc -eq 0 ] && return 0
    # isolate failing names: report them, retry the rest individually-lite
    _error "brew batch failed ($rc); isolating:"
    local p
    for p in "${pkgs[@]}"; do
        if brew list --formula "$p" >/dev/null 2>&1; then
            echo "  ✓ $p"
        else
            _error "failed: $p (run 'brew install $p' to see why)"
        fi
    done
    return 1
}

install_profile_packages() {
    _process "Installing profile packages ($PROFILES / $PKG)"
    local main=() back=() pkg
    while read -r pkg; do
        [ -n "$pkg" ] || continue
        if in_backports "$pkg"; then back+=("$pkg"); else main+=("$pkg"); fi
    done < <(declared_packages | sort -u)

    local failed=0
    case "$PKG" in
    apt)
        apt_batch main "${main[@]}" || failed=1
        apt_batch backports "${back[@]}" || failed=1
        ;;
    brew) brew_batch "${main[@]}" || failed=1 ;;
    *) _error "Unsupported package manager: $PKG"; return 1 ;;
    esac

    [ $failed -eq 0 ] && _success "Package install complete (${#main[@]} + ${#back[@]} backports)"
    return $failed
}