# opt/source — source-build tier

Manifests and scripts live here, in git; the build root does not. `PKGS_ROOT`
defaults to this directory, but the installer points it at the per-machine,
gitignored `~/pkgs`, which holds `src/`, `builds/` and `packages/` — the `.conf`
files are copied there because the scripts read `$PKGS_ROOT/packages/<name>.conf`.

Invocation (see `scripts/debian/configure_system.sh`):

    PKGS_ROOT=~/pkgs HOME_BIN=~/.local/bin bash opt/source/scripts/build.sh <pkg>

Commands:

    scripts/build.sh [--force] [--no-link] [pkg]   # build + install (dep order)
    scripts/update.sh [--force] [pkg]              # bump: git fetch+reset / re-extract
    scripts/check.sh                               # do installed binaries still load here?
    scripts/check.sh --self-test                   # prove the detector still fires

Manifest fields: `pkg_name`, `pkg_version`, `pkg_type` (git|tarball),
`pkg_src_dir`, `pkg_url`, `pkg_branch` (git: branch or tag pin), `pkg_tarball`
+ `pkg_sha256` (tarball: verified on every download), `pkg_build`
(autotools|cmake|make), `pkg_prefix`, `pkg_deps`, `pkg_configure_args` /
`pkg_cmake_args`, `pkg_bin` (what `review_packages.sh` / `check_parity.sh`
report on), `pkg_profiles` (optional gate: build only for those profiles).

## When the system toolchain moves

Builds here inherit the glibc/libstdc++ of the machine that linked them, so a
system that moves *backwards* (dropping a newer repo, `apt --allow-downgrades`,
an image rebase) orphans every binary built before the move:

    nvim: /lib/x86_64-linux-gnu/libc.so.6: version `GLIBC_2.42' not found (required by nvim)

Upgrades are harmless — a newer libc still runs older binaries. Downgrades
cannot be patched around: `LD_*` cannot invent symbol versions the libc no
longer has, so the cure is a relink.

    scripts/check.sh                 # which binaries no longer load? (exit 1 if any)
    scripts/build.sh --force <pkg>   # relink: wipes the build dir so the link reruns

`check.sh` runs automatically at the end of `build.sh` / `update.sh` and exits
non-zero when something does not load, which also stops a caller like
`configure_system.sh` — deliberate: a tool that cannot start is a broken
install, and the printed `--force` command is the fix. `--force` is the
load-bearing part of it: with no source changes, cmake/ninja/make consider the
binary up to date, skip the link, and reinstall the *old* one (measured:
identical sha256 without it).

To keep the system from moving backwards at all, the compiler and the runtime
libraries must come from the same suite — no other repo may supply glibc/gcc.
If a newer suite is ever enabled, pin it in `/etc/apt/preferences.d/00-pkgs-toolchain`:

    Package: libc6 libc6-dev libc-bin libc6-i386 libstdc++6 libgcc-s1 gcc g++ cpp gcc-* g++-* libstdc++-*-dev libgcc-*-dev
    Pin: release o=Debian
    Pin-Priority: 1001

Binaries deliberately built against an *older* glibc (a `debian:bookworm`
container, `zig cc`) survive that too — which is why upstream release tarballs
run on ancient distros, and why the vendored `/opt/nvim-linux-x86_64` build
(needs only glibc 2.34) is a ready-made fallback.
