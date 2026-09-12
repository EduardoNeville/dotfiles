#!/usr/bin/env bash
# review_packages.sh — periodic imperative-package review (the single-user Renovate).
#   candidates: installed manually, not in any dotfiles list → consider adding
#   drift:      declared in dotfiles, not installed → run install.sh
#   source:     opt/source binaries missing / git pins stale
#   fresh:      upgradable + backports candidates (advisory)
# Runs via systemd user timer (profiles/base/services/) on Debian; manually on macOS.
# Usage: bash scripts/review_packages.sh   (exit 1 = action needed)

set -u
DOTFILES="${DOTFILES_DIR:-$HOME/dotfiles}"
DOTFILES_DIR="$DOTFILES"
OUT="$HOME/dotfiles-review-$(hostname 2>/dev/null || echo unknown).md"
fail=0

source "${DOTFILES}/scripts/lib/os.sh"
source "${DOTFILES}/scripts/lib/packages.sh"
detect_os
detect_profile

# apt-mark showmanual includes Debian's own base install — static noise list.
NOISE="adduser apt apt-listchanges apt-transport-https base-files base-passwd bash bc bind9 bsdutils busybox bzip2 ca-certificates console-setup coreutils cpio cron dash dbus debconf debian- debianutils dhcpcd-base diffutils dkms dmidecode doc-debian dpkg e2fsprogs fdisk file findutils gcc-14-base gettext grep groff-base grub- gzip hostname ifupdown inetutils-telnet init init-system-helpers iproute2 iptables iputils-ping isc-dhcp-client kmod libc6 libgcc login logrotate losetup man-db manpages mawk mount nano ncurses-base ncurses-bin openssh-client openssh-server passwd perl perl-base procps readline-common sed sensible-utils sysvinit-utils tar tasksel tzdata udev util-linux vim-common vim-tiny whiptail wget xz-utils zlib1g"
is_noise() { for n in $NOISE; do case "$1" in "$n"*) return 0 ;; esac; done; return 1; }
noise_re=""
for n in $NOISE; do noise_re+="^$n|"; done
noise_re="${noise_re%|}"

{
    echo "# Dotfiles review — $(hostname) — $(date -I)"
    echo ""

    echo "## Drift (declared in dotfiles, NOT installed — run ./install.sh)"
    manual="$(case "$PKG" in apt) apt-mark showmanual | sort ;; brew) brew leaves --installed-on-request | sort ;; esac)"
    known="$(declared_packages | sort -u)"
    drift="$(comm -13 <(echo "$manual") <(echo "$known"))"
    if [ -z "$drift" ]; then
        echo "  ✓ none"
    else
        echo "$drift" | sed 's/^/  ✗ /'
        fail=1
    fi
    echo ""

    echo "## Candidates (installed manually, NOT declared — add to a profile list?)"
    cand="$(comm -23 <(echo "$manual") <(echo "$known") | grep -vE "$noise_re")"
    if [ -z "$cand" ]; then
        echo "  ✓ none"
    else
        echo "$cand" | sed 's/^/  ? /'
        fail=1
    fi
    echo ""

    echo "## Source-built (opt/source)"
    for conf in "$DOTFILES"/opt/source/packages/*.conf; do
        [ -f "$conf" ] || continue
        pkg_name="" pkg_bin="" pkg_branch="" pkg_src_dir=""
        # shellcheck disable=SC1090
        source "$conf"
        if [ -n "$pkg_bin" ] && has "$pkg_bin"; then
            printf '  ✓ %s (%s)\n' "$pkg_name" "$("$pkg_bin" --version 2>/dev/null | head -1 || true)"
        else
            printf '  ✗ %s missing (%s) — build: PKGS_ROOT=~/pkgs opt/source/scripts/build.sh %s\n' "$pkg_name" "$pkg_bin" "$pkg_name"
            fail=1
        fi
    done
    echo ""

    echo "## Freshness (advisory)"
    case "$PKG" in
    apt)
        echo "  upgraded available:"
        apt list --upgradable 2>/dev/null | tail -n +2 | sed 's/^/    /'
        # backports candidates for declared packages (tier-1 decision aid)
        echo "  backports-candidates (per declared pkg, newer in -backports):"
        while read -r pkg; do
            [ -n "$pkg" ] || continue
            pol="$(apt-cache policy "$pkg" 2>/dev/null | sed -n '/Candidate/,+1p')"
            back="$(apt-cache policy "$pkg" 2>/dev/null | sed -n '/trixie-backports/p' | head -1)"
            [ -n "$back" ] && echo "    $pkg → $back"
        done < <(declared_packages | sort -u | head -150)
        ;;
    brew)
        brew outdated --verbose 2>/dev/null | sed 's/^/    /'
        ;;
    esac
} | tee "$OUT"

echo ""
echo "review written to $OUT"
exit $fail