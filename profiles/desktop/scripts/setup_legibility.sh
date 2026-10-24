#!/usr/bin/env bash
# setup_legibility.sh — install-time defaults for panel brightness and text size.
#
# Declares nothing itself. Everything that can be a file is either linked by
# link_dotfiles (configs/fontconfig → ~/.config/fontconfig) or read straight
# from the repo at session start (profiles/desktop/configs/Xresources). What is
# left is per-user state that cannot be symlinked, plus verification:
#
#   1. dependencies this feature actually needs (declared in packages.apt)
#   2. the Firefox per-profile page-scale block (profiles are created by
#      Firefox, so firefox_legibility.sh generates it; also re-run at login)
#   3. a fontconfig cache refresh, so a fresh install renders correctly on the
#      first session instead of after the first fc-cache
#   4. if run from inside a live session: apply Xresources and the saved
#      brightness immediately (otherwise the next login does it)
#
# Idempotent by design: a second `install.sh` changes nothing here.
#
# Called by scripts/debian/configure_system.sh for the desktop profile.

set -u

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
SCRIPTS="${DOTFILES_DIR}/profiles/desktop/scripts"
XRES="${DOTFILES_DIR}/profiles/desktop/configs/Xresources"
FONTS_CONF="${DOTFILES_DIR}/configs/fontconfig/fonts.conf"

_process() { echo "$(tput setaf 6)→ $1...$(tput sgr0)"; }
_success() { echo "$(tput setaf 2)✓ Success:$(tput sgr0) $1"; }
_error() { echo "$(tput setaf 1)✗ Error:$(tput sgr0) $1"; }

missing=0

check_deps() {
    _process "Checking legibility dependencies"
    # xrandr/xrdb come from x11-xserver-utils (pulled in by xorg, declared
    # explicitly in packages.apt because lut.py needs libXrandr at runtime).
    for bin in brightnessctl python3 xrdb xrandr; do
        command -v "$bin" >/dev/null 2>&1 || {
            _error "$bin not found — declared in profiles/desktop/packages.apt"
            missing=1
        }
    done
    for f in "$XRES" "$FONTS_CONF" "$SCRIPTS/lut.py" "$SCRIPTS/light.sh" "$SCRIPTS/firefox_legibility.sh"; do
        [ -e "$f" ] || {
            _error "missing $f"
            missing=1
        }
    done
    # Import without opening a display: catches a Xlib/Xrandr soname problem at
    # install time instead of the first key press after login. -B keeps
    # __pycache__ out of the checkout: running install must not dirty the repo.
    if command -v python3 >/dev/null 2>&1; then
        python3 -B -c 'import sys; sys.path.insert(0, sys.argv[1]); import lut' "$SCRIPTS" 2>/dev/null ||
            {
                _error "lut.py cannot load libX11/libXrandr"
                missing=1
            }
    fi
    [ "$missing" -eq 0 ] && _success "dependencies present"
}

apply_firefox() {
    _process "Applying Firefox page scale (per profile)"
    if [ ! -x "$SCRIPTS/firefox_legibility.sh" ]; then
        _error "firefox_legibility.sh not executable"
        return 1
    fi
    "$SCRIPTS/firefox_legibility.sh" || {
        _error "could not write the Firefox user.js block"
        return 1
    }
}

refresh_fonts() {
    command -v fc-cache >/dev/null 2>&1 || return 0
    _process "Refreshing fontconfig cache (new fonts.conf)"
    fc-cache -f >/dev/null 2>&1 || true
}

apply_live() {
    [ -n "${DISPLAY:-}" ] || return 0
    _process "Applying to the running session"
    [ -f "$XRES" ] && command -v xrdb >/dev/null 2>&1 && xrdb -merge "$XRES"
    [ -x "$SCRIPTS/light.sh" ] && "$SCRIPTS/light.sh" restore >/dev/null 2>&1
    _success "Xft.dpi and brightness re-applied (dwm itself picks dpi up at next login)"
}

summary() {
    local level scale dpi
    level="$("$SCRIPTS/light.sh" default 2>/dev/null || echo 120)"
    scale="${FIREFOX_LEGIBILITY_SCALE:-1.15}"
    dpi=$(awk '/^Xft\.dpi/ { print $2 }' "$XRES" 2>/dev/null)
    echo ""
    _success "Desktop legibility defaults in place"
    echo "  brightness  0-130% via light.sh (keys: XF86MonBrightnessUp/Down)"
    echo "              fresh session starts at ${level}% = hardware 100% + midtone curve"
    echo "  Xft.dpi     ${dpi:-110} (Xresources, merged by dwm-session.sh; XSETTINGS carries it to GTK)"
    echo "  Firefox     devPixelsPerPx ${scale} for page content (per profile user.js)"
    echo "  Tunable:    LIGHT_DEFAULT / LIGHT_CEILING / LIGHT_STEP in the environment,"
    echo "              LIGHT_STRENGTH in lut.py, FIREFOX_LEGIBILITY_SCALE for Firefox."
    echo "  Details:    notes/backlight-legibility-plan.md"
}

main() {
    check_deps
    apply_firefox
    refresh_fonts
    apply_live
    summary
    # A missing binary is reported above; do not fail the whole install for a
    # cosmetic layer, but make the exit status honest for --links-only runs.
    [ "$missing" -eq 0 ] || exit 1
}

main "$@"
