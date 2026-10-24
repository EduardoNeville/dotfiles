#!/bin/sh
# firefox_legibility.sh — keep Firefox's *web content* sized for this panel.
#
# Firefox lays pages out in CSS pixels and maps them 1:1 to device pixels
# unless told otherwise, so on the T480's 157dpi panel (14", 1920x1080) page
# text renders physically ~15% smaller than the rest of the desktop. Chrome
# (tabs, menus) is GTK and already follows Xft/DPI from xsettingsd; only the
# page content needs its own scale.
#
# Why a generated block instead of a shipped file: Firefox creates and names
# profiles itself, so there is nothing stable to symlink. user.js is the right
# place because Firefox re-applies it at every start, while prefs.js gets
# rewritten on exit (edits there are lost).
#
#   firefox_legibility.sh            apply/refresh every existing profile
#   firefox_legibility.sh --check    silent; exit 1 if a profile drifts
#
# The block is marked, so the rest of user.js is never touched and repeated
# runs are no-ops. Scale comes from $FIREFOX_LEGIBILITY_SCALE (default 1.15).

set -u

SCALE="${FIREFOX_LEGIBILITY_SCALE:-1.15}"
CHECK=0
[ "${1:-}" = "--check" ] && CHECK=1

BEGIN_MARK='// >>> dotfiles legibility >>>'
END_MARK='// <<< dotfiles legibility <<<'

# Debian 13 (and macOS) keep profiles under the XDG dir; older Debian used
# ~/.mozilla. Scan both so a migrated machine does not silently lose the pref.
profile_dirs() {
    for base in "${XDG_CONFIG_HOME:-$HOME/.config}/mozilla/firefox" "$HOME/.mozilla/firefox"; do
        [ -d "$base" ] || continue
        for dir in "$base"/*/; do
            # prefs.js is what distinguishes a real profile from Profile Groups/
            # Crash Reports/ and other bookkeeping directories.
            [ -f "$dir/prefs.js" ] && printf '%s\n' "${dir%/}"
        done
    done
}

block() {
    cat <<EOF
$BEGIN_MARK
// Page scale for the 157dpi panel: CSS px map 1:1 to device px by default,
// which renders web text ~15% small here. GTK chrome is scaled separately via
// Xft/DPI (configs/theme/scripts/gtk_theme.sh).
// Managed by profiles/desktop/scripts/firefox_legibility.sh — edit \$SCALE there.
user_pref("layout.css.devPixelsPerPx", "$SCALE");
$END_MARK
EOF
}

strip_block() {
    awk -v b="$BEGIN_MARK" -v e="$END_MARK" '
        index($0, b) { skip = 1; next }
        index($0, e) { skip = 0; next }
        !skip        { print }
    '
}

check_one() {
    [ -n "$1" ] && [ -d "$1" ] || return 1
    target="$1/user.js"
    [ -f "$target" ] || return 1
    grep -qF "$BEGIN_MARK" "$target" 2>/dev/null || return 1
    grep -qF "user_pref(\"layout.css.devPixelsPerPx\", \"$SCALE\");" "$target" 2>/dev/null || return 1
    return 0
}

# 0 = written, 1 = unchanged, 2 = failed
apply_one() {
    dir="$1"
    # An empty command substitution yields one empty line; a deleted HOME yields
    # a path we cannot write. Both must be no-ops, not "cannot write /user.js".
    [ -n "$dir" ] && [ -d "$dir" ] && [ -w "$dir" ] || return 2
    target="$dir/user.js"
    tmp="$dir/.user.js.dotfiles.$$"
    {
        [ -f "$target" ] && strip_block <"$target"
        block
    } >"$tmp" 2>/dev/null || { rm -f "$tmp"; return 2; }
    if [ -f "$target" ] && cmp -s "$tmp" "$target"; then
        rm -f "$tmp"
        return 1
    fi
    # prefs.js is 0600; match it — a world-readable user.js would be odd.
    chmod 600 "$tmp" 2>/dev/null || true
    mv -f "$tmp" "$target" || { rm -f "$tmp"; return 2; }
    return 0
}

seen=0
written=0
drift=0
failed=0
while IFS= read -r dir; do
    [ -n "$dir" ] || continue
    seen=$((seen + 1))
    if [ "$CHECK" -eq 1 ]; then
        check_one "$dir" || drift=$((drift + 1))
        continue
    fi
    apply_one "$dir"
    case $? in
    0) written=$((written + 1)) ;;
    2) failed=$((failed + 1)); printf 'firefox_legibility: cannot write %s/user.js\n' "$dir" >&2 ;;
    esac
done <<EOF
$(profile_dirs)
EOF

if [ "$CHECK" -eq 1 ]; then
    [ "$drift" -eq 0 ] || exit 1
    exit 0
fi

if [ "$seen" -eq 0 ]; then
    # Normal on a fresh install: Firefox has not been started yet, so no
    # profile exists. dwm-session.sh re-runs this at every login and picks the
    # profile up once Firefox creates it.
    printf 'firefox_legibility: no Firefox profile yet (runs again at next login)\n'
    exit 0
fi
if [ "$failed" -gt 0 ]; then
    exit 1
fi
[ "$written" -gt 0 ] && printf 'firefox_legibility: page scale %s applied to %s profile(s)\n' "$SCALE" "$written"
exit 0
