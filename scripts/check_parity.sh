#!/usr/bin/env bash
# Drift check: verify this machine actually points at the dotfiles/dotpi configs.
# Portable (macOS + Debian). Run after any install, or via cron/launchd.
#   bash scripts/check_parity.sh            (exit 1 = drift found)
#   bash scripts/check_parity.sh --packages (also verify declared packages + source tools)
# Profile-aware: desktop configs are expected to be absent on base-only hosts.

set -u
DOTFILES="${DOTFILES_DIR:-$HOME/dotfiles}"
DOTFILES_DIR="$DOTFILES"
DOTPI="$HOME/dotpi"
fail=0
CHECK_PACKAGES=0
[ "${1:-}" = "--packages" ] && CHECK_PACKAGES=1

source "${DOTFILES}/scripts/lib/os.sh"
source "${DOTFILES}/scripts/lib/packages.sh"
detect_os
detect_profile

ok() { echo "  ✓ $1"; }
bad() { echo "  ✗ $1"; fail=1; }

resolve() { readlink -f "$1" 2>/dev/null || python3 -c 'import os,sys;print(os.path.realpath(sys.argv[1]))' "$1"; }

chk_link() { # chk_link <link-path> <expected-source>
    local t="$1" src="$2"
    if [ -L "$t" ] && [ "$(resolve "$t")" = "$(resolve "$src")" ]; then
        ok "$t"
    else
        bad "$t not linked to $src"
    fi
}

echo "== shell / git / ssh =="
chk_link "$HOME/.zshrc" "$DOTFILES/configs/zsh-conf/zshrc"
chk_link "$HOME/.zprofile" "$DOTFILES/configs/zsh-conf/zprofile"
chk_link "$HOME/.gitconfig" "$DOTFILES/configs/.gitconfig"
chk_link "$HOME/.ssh/config" "$DOTFILES/configs/ssh/config"

echo "== ~/.config (universal) =="
for d in "$DOTFILES"/configs/*/; do
    [ -d "$d" ] || continue
    name=$(basename "$d")
    case "$name" in .git* | ssh) continue ;; esac
    chk_link "$HOME/.config/$name" "${d%/}"
done

echo "== ~/.config (profiles: $PROFILES) =="
for p in $PROFILES; do
    for d in "$DOTFILES"/profiles/$p/configs/*/; do
        [ -d "$d" ] || continue
        name=$(basename "$d")
        chk_link "$HOME/.config/$name" "${d%/}"
    done
    [ -f "$DOTFILES/profiles/$p/configs/xinitrc" ] && chk_link "$HOME/.xinitrc" "$DOTFILES/profiles/$p/configs/xinitrc"
done

echo "== shadowed configs (real dirs blocking repo symlinks) =="
for d in "$DOTFILES"/configs/*/ "$DOTFILES"/profiles/$PROFILES/configs/*/; do
    [ -d "$d" ] || continue
    name=$(basename "$d")
    case "$name" in .git* | ssh) continue ;; esac
    t="$HOME/.config/$name"
    if [ -e "$t" ] && [ ! -L "$t" ]; then
        bad "$t is a real directory — shadows $d (delete or back it up, re-run install.sh)"
    fi
done

echo "== pi (dotpi) =="
chk_link "$HOME/.pi/agent/settings.json" "$DOTPI/settings.json"
chk_link "$HOME/.pi/agent/trust.json" "$DOTPI/trust.json"
chk_link "$HOME/.config/ponytail/config.json" "$DOTPI/extensions/ponytail/config.json"

if [ "$CHECK_PACKAGES" = "1" ]; then
    echo "== declared packages vs installed =="
    missing=()
    while read -r pkg; do
        [ -n "$pkg" ] || continue
        case "$PKG" in
        apt) dpkg -s "$pkg" >/dev/null 2>&1 || missing+=("$pkg") ;;
        brew) brew list --formula "$pkg" >/dev/null 2>&1 || missing+=("$pkg") ;;
        esac
    done < <(declared_packages | sort -u)
    if [ "${#missing[@]}" -eq 0 ]; then
        ok "all declared packages installed"
    else
        bad "declared but missing: ${missing[*]} (run install.sh)"
    fi

    echo "== source-built tools (opt/source) =="
    for conf in "$DOTFILES"/opt/source/packages/*.conf; do
        [ -f "$conf" ] || continue
        pkg_name=""
        pkg_bin=""
        pkg_profiles=""
        # shellcheck disable=SC1090
        source "$conf"
        [ -n "$pkg_bin" ] || continue
        # Same profile gate as ensure_source_pkgs — desktop-only tools are
        # not expected on base-only hosts.
        if [ -n "$pkg_profiles" ]; then
            case " $PROFILES " in *" $pkg_profiles "*) ;; *) continue ;; esac
        fi
        if has "$pkg_bin"; then
            ok "$pkg_name ($pkg_bin)"
        else
            bad "$pkg_name missing ($pkg_bin) — build with opt/source/scripts/build.sh"
        fi
    done
fi

if [ "$fail" -eq 0 ]; then
    echo ""
    echo "✓ Parity OK — all configs point at the repo"
else
    echo ""
    echo "✗ Drift found (see ✗ lines above)"
fi
exit $fail