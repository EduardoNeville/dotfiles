#!/usr/bin/env bash
# check.sh — do the installed binaries still load on THIS system?
#
# Catches the one failure mode source builds are exposed to: a build inherits
# the glibc/libstdc++ of the machine that linked it, so when the system moves
# *backwards* (dropping a newer repo, apt --allow-downgrades, an image rebase)
# every binary built before the move dies at exec with e.g.
#   nvim: /lib/x86_64-linux-gnu/libc.so.6: version `GLIBC_2.42' not found
# No LD_* variable can fix that: the symbol versions are simply not in the libc
# any more, so the only cure is a relink (build.sh --force).
#
# Usage:
#   ./scripts/check.sh              # scan $PKGS_ROOT/builds (same default as
#                                   # common.sh: override PKGS_ROOT=~/pkgs)
#   ./scripts/check.sh <dir> [...]  # scan other dirs
#   ./scripts/check.sh --self-test  # prove the detector still fires on a bad ELF
#
# Exit: 0 = everything loads, 1 = something is broken (rebuild it).
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Same default + override contract as common.sh; kept local so this can be run
# standalone (and so it holds no build state).
PKGS_ROOT="${PKGS_ROOT:-$(cd "$DIR/.." && pwd)}"
PREFIX_ROOT="$PKGS_ROOT/builds"

# Ask the dynamic loader itself. One quiet ldd run per ELF; report the first
# "not found" it prints — that covers both a missing symbol version and a
# missing library. Scripts (bin/event_rpcgen.py) are skipped by the ELF magic.
loader_complaint() {
  head -c 4 -- "$1" 2>/dev/null | grep -q $'\x7fELF' || return 0
  ldd -- "$1" 2>&1 | grep -m1 'not found' || true
}

scan() {
  local d f complaint
  for d in "$@"; do
    [ -d "$d" ] || continue
    while IFS= read -r f; do
      complaint="$(loader_complaint "$f")"
      [ -n "$complaint" ] && BROKEN+=("$f: $complaint")
    done < <(find "$d" -type f \( -path '*/bin/*' -o -name '*.so' -o -name '*.so.*' \) | sort)
  done
  return 0
}

# --- self-test: a real ELF demanding a libc version no system ever had -------
if [ "${1:-}" = "--self-test" ]; then
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  mkdir -p "$tmp/bin"
  printf '%s\n' 'extern int puts(const char *);' \
    'int fake(void) { return puts("x"); }' > "$tmp/fake.c"
  cc -shared -fPIC -o "$tmp/bin/libfake.so" "$tmp/fake.c" \
    || { echo "self-test SKIPPED (no working cc)"; exit 0; }
  # ld refuses to *link* a bogus version, so rewrite a real one in place: same
  # length, so the ELF stays valid — the exact shape of a stale build.
  perl -0777 -pi -e 's/GLIBC_2\.2\.5/GLIBC_2.9.9/' "$tmp/bin/libfake.so"
  BROKEN=()
  scan "$tmp"
  if [ "${#BROKEN[@]}" -eq 0 ]; then
    echo "self-test FAILED: detector missed a GLIBC_2.9.9 requirement"
    exit 1
  fi
  echo "self-test ok: detector fired on ${BROKEN[0]#*: }"
  exit 0
fi

BROKEN=()
if [ "$#" -gt 0 ]; then
  scan "$@"
else
  if [ ! -d "$PREFIX_ROOT" ]; then
    echo "nothing to check: $PREFIX_ROOT does not exist (set PKGS_ROOT=~/pkgs, or build first)"
    exit 0
  fi
  scan "$PREFIX_ROOT"
fi

if [ "${#BROKEN[@]}" -eq 0 ]; then
  echo "OK: every built binary in $PREFIX_ROOT loads ($(getconf GNU_LIBC_VERSION 2>/dev/null || echo 'libc unknown'))"
  exit 0
fi

echo "BROKEN: ${#BROKEN[@]} file(s) linked against a newer toolchain than this system has"
for b in "${BROKEN[@]}"; do echo "  $b"; done
echo
echo "rebuild them (--force wipes the build dir so the link step really reruns):"
# When PKGS_ROOT was overridden (the repo copy normally is), the suggestion has
# to carry it too or the rebuild would target the wrong tree.
env_prefix=""
[ "$PKGS_ROOT" != "$(cd "$DIR/.." && pwd)" ] && env_prefix="PKGS_ROOT=$PKGS_ROOT "
declare -A suggested=()
for b in "${BROKEN[@]}"; do
  prefix="${b#"$PREFIX_ROOT"/}"
  prefix="${prefix%%/*}"
  name="$(basename "$(grep -l "^pkg_prefix=$prefix$" "$PKGS_ROOT"/packages/*.conf 2>/dev/null | head -1)" .conf)"
  target="${name:-$prefix}"
  [ -n "${suggested[$target]:-}" ] && continue
  suggested[$target]=1
  echo "  ${env_prefix}$DIR/build.sh --force $target"
done
exit 1
