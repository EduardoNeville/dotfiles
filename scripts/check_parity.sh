#!/usr/bin/env bash
# Drift check: verify this machine actually points at the dotfiles/dotpi configs.
# Portable (macOS + Debian). Run after any install, or via cron/launchd.
# Usage: bash scripts/check_parity.sh   (exit 1 = drift found)

set -u
DOTFILES="${DOTFILES_DIR:-$HOME/dotfiles}"
DOTPI="$HOME/dotpi"
fail=0

ok() { echo "  ✓ $1"; }
bad() { echo "  ✗ $1"; fail=1; }

# resolve() prints canonical path of a symlink (portable)
resolve() { readlink -f "$1" 2>/dev/null || python3 -c 'import os,sys;print(os.path.realpath(sys.argv[1]))' "$1"; }

chk_link() { # chk_link <link-path> <expected-source>
    local t="$1" src="$2"
    if [ -L "$t" ] && [ "$(resolve "$t")" = "$(resolve "$src")" ]; then
        ok "$t"
    else
        bad "$t not linked to $src"
    fi
}

echo "== shell / git =="
chk_link "$HOME/.zshrc" "$DOTFILES/configs/zsh-conf/zshrc"
chk_link "$HOME/.gitconfig" "$DOTFILES/configs/.gitconfig"

echo "== ~/.config =="
for d in "$DOTFILES"/configs/*/; do
    name=$(basename "$d")
    case "$name" in suckless | services | .git*) continue ;; esac
    chk_link "$HOME/.config/$name" "${d%/}"
done

echo "== pi (dotpi) =="
chk_link "$HOME/.pi/agent/settings.json" "$DOTPI/settings.json"
chk_link "$HOME/.pi/agent/trust.json" "$DOTPI/trust.json"
chk_link "$HOME/.config/ponytail/config.json" "$DOTPI/extensions/ponytail/config.json"

echo "== shadowed configs (real dirs blocking repo symlinks) =="
for d in "$DOTFILES"/configs/*/; do
    name=$(basename "$d")
    case "$name" in suckless | services | .git*) continue ;; esac
    t="$HOME/.config/$name"
    if [ -e "$t" ] && [ ! -L "$t" ]; then
        bad "$t is a real directory — shadows $d (delete or back it up, re-run configure_system.sh)"
    fi
done

if [ "$fail" -eq 0 ]; then
    echo ""
    echo "✓ Parity OK — all configs point at the repo"
else
    echo ""
    echo "✗ Drift found (see ✗ lines above)"
fi
exit $fail
