# Dotfiles Redesign — Profile-Based Plan (2026-09)

## Context

- `dotnix` failed: it layered a second package manager (nix) on top of apt/brew
  systems that were already stateful. Two sources of truth, constant drift.
  → **Retire dotnix. One package manager per OS, one source of truth (this repo).**
- The bash engine already built (`install.sh`, `scripts/lib/{os,link,packages}.sh`,
  `check_parity.sh`) works and stays. What's broken:
  1. No host dimension — every machine links every config (`configs/*`),
     including sway/waybar/wofi on a headless server.
  2. `opt/debianPkgs` is a monolithic mix of server, laptop and GUI packages.
  3. Imperatively-installed packages drift silently; nothing reconciles them
     with the repo lists.

## Target model — 3 profiles

| Machine     | OS           | Profile(s)                     |
|-------------|--------------|--------------------------------|
| deep-blue   | Debian 13    | `base` (headless server)       |
| hydra       | Debian 13    | `base` + `desktop` (dwm, X11)  |
| i-mac       | macOS        | `base` via brew                |

`base` = everything needed on every machine (shell, editors, git, languages,
containers, monitoring). `desktop` = only hydra (WM, audio, bluetooth, power,
GUI apps). i-mac gets the same *tools* as base, installed by brew.

## New structure

```
dotfiles/
├── install.sh                  # entrypoint: os detect → profile resolve → packages → links → parity
├── apt-sources/debian.sources  # base apt sources: trixie + updates + security + backports (deb822)
├── hosts/<hostname>            # optional, e.g. hosts/hydra:  PROFILE="base desktop"
│                               #   plus hosts/<hostname>/packages.{apt,brew} for per-host extras
│                               #   plus hosts/<hostname>/apt-sources/*.sources (per-host vendor repos)
│                               #   (deep-blue: HP tools amsd/hponcfg/ssacli/storcli, docker-ce, postgres)
├── profiles/
│   ├── base/
│   │   ├── packages.common     # names identical on apt AND brew — every machine
│   │   ├── packages.apt        # debian base: fs tools, latex, docker, libvirt, dev libs
│   │   ├── packages.brew       # brew equivalents (coreutils, openjdk, rust, pyenv, ...)
│   │   ├── casks.txt           # mac-only casks (font-hack-nerd-font, maccy, ...)
│   │   ├── taps.txt            # mac-only `brew tap` lines (bun, zathura, ...)
│   │   └── scripts/            # shared system config: groups, fonts, systemd base services
│   └── desktop/
│       ├── packages.common
│       ├── packages.apt        # xorg, dwm deps, pipewire, bluez, tlp, GUI apps
│       ├── configs/            # suckless/, rofi/, solaar/, mpd/, rmpc/, services/
│       └── scripts/            # setup_audio.sh, install_suckless.sh (moved from scripts/debian/)
├── configs/                    # UNIVERSAL configs only: zsh, nvim, git, tmux, starship,
│                               #   wezterm, pi, opencode, television, nnn, btop, theme?, ...
├── scripts/
│   ├── lib/{os,link,packages}.sh   # engine — profile-aware, otherwise unchanged
│   ├── check_parity.sh             # + --packages mode (declared-but-missing detection)
│   ├── review_packages.sh          # NEW: imperative-package review (see below)
│   └── macos/configure_system.sh   # taps, casks, chsh
└── opt/
    ├── backports.txt            # Tier 1 opt-in: one pkg per line → `apt-get -t trixie-backports install`
    ├── debs/                    # Tier 3 local .deb pins: `apt install -y ./debs/*.deb`
    ├── source/                  # Tier 4 SOURCE-BUILD manifests+scripts (formalized ~/pkgs)
    ├── cargoPkgs, nodePkgs, pip, zsh_plugins   # unchanged
    └── (debianPkgs, Brewfile, common.txt → deleted after triage)

~/pkgs/ remains the per-machine build ROOT (src/, builds/, bin/) — gitignored,
~1.2 GB, not portable. Only manifests+scripts live in dotfiles.
```

### Profile resolution (no config burden)
1. `PROFILE=...` env or `install.sh --profile base,desktop` wins (fresh installs).
2. Else `hosts/$(hostname)` file (only hydra needs one).
3. Else default: `base` (deep-blue, i-mac need nothing).

`check_parity.sh` resolves the profile the same way, so desktop configs missing
on deep-blue are *expected*, not drift.

### Linking rules (link.sh)
- `configs/*` → linked on every machine (union, as today).
- `profiles/<active>/configs/*` → linked additionally.
- Skip logic: a config whose app isn't installed gets skipped on `--check`
  (link only when `has <binary>` for desktop entries, e.g. `dwm`, `waybar`).

### Package rules
- Merge order per machine: `profiles/<active>/packages.{common,apt,brew}` +
  `hosts/<hostname>/packages.{apt,brew}` (per-host extras like HP tools,
  docker-ce repo packages, postgres — never shared).
- `packages.common` on every OS requires identical names (current common.txt
  grows: eza, starship, git-delta, zoxide, tmux, neovim already, ...).
- Name mismatches (`fd-find` vs `fd`, `docker.io` vs `docker`) live in the
  per-OS files. No overrides machinery — the mismatch set is ~5 names.
- Desktop `.deb` pins (none needed today) go in `opt/debs/` and are installed
  with `sudo apt-get install -y ./opt/debs/*.deb` (resolves deps, unlike dpkg -i).
- Heavy tooling (cargo/npm/pip lists) stays as today: installed by the adapter
  script after the package manager, guarded by `has()`.

## Version policy — tiered freshness (how the pros keep Debian fresh)

Per-tool tier decision (applied during triage), documented so every package has
a declared home. One source per tier, no implicit mixing — the
DontBreakDebian/Debian-backports contract:

| Tier | Source | Rule |
|------|--------|------|
| 0 | Debian stable | default. Versions float within release (security-tracked); 99% of packages. |
| 1 | trixie-backports | per-package **declared** opt-in in `opt/backports.txt`; installed `-t trixie-backports`; backports stay pinned at priority 100 so nothing upgrades implicitly. |
| 2 | vendor repos (official only) | docker-ce, tailscale, google-chrome, gh. Per-host `hosts/<h>/apt-sources/*.sources` (deb822). Keyring: official URL fetched at bootstrap (docker/tailscale/gh) or shipped by vendor .deb (chrome/hpe/redis) — never curl\|bash. |
| 3 | vendor .deb in `opt/debs/` | no repo exists; `apt install -y ./opt/debs/*.deb` (deps resolve). |
| 4 | source build via `opt/source/` | nothing newer exists packaged; keep tiny (nvim, tmux + private deps). macOS never: brew is tier-0-4 all at once. |
| 5 | ecosystem managers — win over apt | rustup+cargo, npm/bun, pipx/uv, fnm/nvm, go. **Rule (locked 2026-09): if a tool ships through its own ecosystem manager, install through it even when apt has it.** apt only for distro/system packages (libs, services, GUI, desktop components). |

Desktop GUI apps that Debian lacks or stales (hydra only): flatpak/Flathub —
the Debian-recommended GUI route; adopt when a GUI app actually needs it.

## Source-build layer (Tier 4 — details)

Per-tool decision ladder (applied during triage, per package):
1. Tier 0–2 covers it? Done there. Trixie reality (2026-09 snapshot): git 2.51,
   rg 14.1, fzf 0.67, starship 1.22, lazygit 0.50, btop 1.4 → tier 0 covers
   most tools fine.
2. Otherwise → source build — **frozen at {neovim, tmux}** (+ libevent, bison
   as build-only deps). Nothing joins without a reason; the known non-candidates:
   - docker → docker-ce vendor repo (already in use on deep-blue), never source
   - nodejs → fnm/nvm toolchain (Debian's node 20 is end-of-lifing; apt and
     source are both wrong tiers)
   - yq/yazi: removed 2026-09 (unused — not installed on any machine, no
     config references; submodule configs/yazi deinit'd)
   - gh/rust/py tools → vendor repo / rustup+uv, their own updaters
   Entry rule for opt/source: upstream ships NO repo/deb/toolchain AND apt is
   unusable. That's why the set stays at two.

`opt/source/` = the existing `~/pkgs` system formalized; logic unchanged:
```
opt/source/
├── scripts/              # common.sh, build.sh, update.sh (moved verbatim)
└── packages/*.conf       # manifests — THE source of truth, tracked in git
```
Per-machine `~/pkgs/` (src/, builds/, bin/) stays a gitignored build root.
`install.sh` (apt machines only) runs a new adapter step `ensure_source_pkgs`:
per conf, build+link when the binary is missing; never sudo.

Production-readiness gaps closed:
- **`pkg_sha256`** in confs: tarballs verified before extract, fail loud.
- **Git pins a tag, not `master`** (`pkg_branch=v0.11.2`). `update.sh` is an
  explicit versioned action; the review loop flags stale tags.
- **Parity**: `check_parity.sh --packages` verifies each conf's
  `builds/<prefix>/bin` binary exists; `review_packages.sh` prints source
  versions (`git describe` / `--version`) so staleness is visible weekly.
- **Builds as user only** (kills the old root-owned neovim build/ problem).
- **macOS skipped**: brew is rolling release; i-mac gets nvim/tmux from
  `base/packages.brew` at current versions.

Source deps stay source deps (libevent/bison → tmux): the conf dep graph +
prefix pkg-config chaining already does this. If a source tool ever becomes a
burden, promote it to `opt/debs/` (vendor .deb) — the ladder is bidirectional.

Why not real .debs for everything? `dpkg-buildpackage` needs a maintained
`debian/` tree per tool; checkinstall is unmaintained; fpm wraps this exact
prefix flow in a Ruby gem and apt-tracks build artifacts dpkg can't reason
about. For 2 pinned tools, the formalized prefix system is the smallest thing
that works.

## Package classification (2026-09 — grounded in live apt-cache + deep-blue snapshot)

### Tier assignment, per tool (the full decision)
| tool | tier | why |
|---|---|---|
| neovim, tmux (+libevent, bison) | **source — frozen {neovim, tmux}** | only genuinely stale: apt 0.10.4/3.5a vs built 0.13-dev/3.7b |
| docker-ce, gh, tailscale, chrome | vendor repo | official repos, auto-update via apt |
| nodejs | fnm/nvm toolchain | apt node 20 is EOL-ing; source = hours of upkeep |
| git 2.51, fzf 0.67, btop 1.4, lazygit 0.50 | apt — fine | distro/system-adjacent tools; no ecosystem manager in play |
| bat/eza/starship/zoxide/ripgrep/fd/git-delta/du-dust/dysk | **cargo** (Tier 5) | Rust tools — ecosystem manager FIRST even though trixie packages them |

### BASE — every machine (deep-blue, hydra base layer, i-mac via brew)
- Shells & prompt: zsh + plugins, bash-completion, starship, tmux (source-built)
- Editor & git: vim, nvim (source-built), git, gh (vendor), lazygit, tree-sitter, delta
- Build: build-essential, gcc/g++, gdb, make, cmake, ninja-build, meson, pkg-config, autoconf, automake, libtool
- Languages: python3 (+venv/pip/dev), golang, default-jdk, luarocks, node via fnm/nvm, rust via rustup, pipx, uv
- Containers: docker-ce (vendor) + compose plugin
- TUI utils: nnn, fzf, ripgrep, fd-find, bat, eza, zoxide, btop, fastfetch, tree, jq
- FS & partitions: btrfs-progs, e2fsprogs, xfsprogs, dosfstools, ntfs-3g, exfatprogs, lvm2, cryptsetup, parted, gparted, smartmontools
- Compression: zip, unzip, p7zip-full, tar, gzip, bzip2, xz-utils, zstd
- Media core: ffmpeg, imagemagick-adjacent (chafa)
- Docs: texlive (+extras/xetex), pandoc, zathura + mupdf
- Monitoring: btop, iotop, sysstat, lm-sensors, smartmontools, fastfetch
- Security: gnupg, pass, openssl, openssh client+server, shellcheck
- Dev libs: libssl-dev, libreadline-dev, libsqlite3-dev, libncurses-dev, libffi-dev, libbz2-dev, liblzma-dev, zlib1g-dev
- Network: curl, wget, rsync, dnsutils, net-tools, tailscale (vendor)

### DESKTOP — hydra only (desktop profile)
- WM: suckless (dwm/slstatus/st, **source — customization-driven**, existing
  submodule + install_suckless.sh; not staleness), rofi, xinit/xorg,
  libx11-dev/libxft-dev/libxinerama-dev, feh, xsel/xclip
- Audio: pipewire, wireplumber, pipewire-pulse, pavucontrol, mpv, vlc, cmus, helvum
- Bluetooth: bluez, blueman
- Power: tlp (+rdw), powertop, brightnessctl, acpi, acpid
- GUI apps: obs-studio, keepassxc, gparted, solaar, redshift(+gtk), fonts
- Media: mpd, rmpc (**cargo install — not packaged in trixie**, checked
  2026-09; goes in opt/cargoPkgs), fbterm, usbmuxd, libmtp libs
- Services: pipewire user units (configs/services)
- **Desktop source count: 1 set (suckless) + 1 cargo (rmpc); ~33 apt.**
  All versions verified current on trixie (pipewire 1.4.2, bluez 5.82,
  obs 30.2, keepassxc 2.7.10, rofi 1.7.5).

### PER-HOST — deep-blue only (hosts/deep-blue/packages.apt)
- HP server tooling: amsd, hponcfg, ssacli, ssaducli, storcli, ipmitool, python3-hpilo
- Services: postgresql, redis, certbot, cloudflared, bind9-dnsutils
- Vendor repos (hosts/<h>/apt-sources/): docker-ce, chrome, gh, hpe, pgdg,
  redis on deep-blue; tailscale is base-wide (all 3 machines). hydra's set
  captured from the machine when online.

## Apt sources (Debian bootstrap)

`apt-sources/debian.sources` = base (trixie, updates, security, declared
backports) for every Debian machine; `hosts/<h>/apt-sources/` = per-host
vendor repos. All deb822, one mechanism. Captured+normalized from deep-blue
2026-09 (live box had mixed one-line/deb822, a duplicate bookworm docker
list, and stray .bak files — all fixed in the repo copy).

**Naming scheme (locked):** `<vendor-shortname>.sources` everywhere, deb822
only. Repo basename == deployed basename, 1:1 copy into
`/etc/apt/sources.list.d/`. Base = `debian.sources`; per-host vendors =
`docker|tailscale|google-chrome|github-cli|hpe-mcp|pgdg|redis.sources`.
Setup step deletes any managed `*.list` / `*.bak` strays — one file per
repo, no rename games at deploy time.

Bootstrap order on a fresh install (`setup_apt_sources`, built in Phase 2):
1. Keyrings FIRST: fetch official keyring URLs (docker gpg, tailscale pubkey,
   gh keyring) or install vendor .deb (chrome/hpe/redis) — never curl|bash.
2. Copy `apt-sources/debian.sources` + active profiles' + host's `.sources`
   → `/etc/apt/sources.list.d/` (union, idempotent).
3. `apt-get update`; backports stay opt-in via `-t trixie-backports`.
4. Cleanup rule: one source file per repo, no .bak/strays — repo copy is the
   source of truth (checked by check_parity --packages).

### i-mac
Same BASE toolset via brew (Brewfile triage: coreutils, openjdk, sqlite, rust,
pyenv, bun, casks font-hack-nerd-font/maccy/multipass; zathura via tap). No
desktop profile, no source layer.

## The periodic review loop (imperative packages)

New `scripts/review_packages.sh`, run by systemd user timer (weekly) on
deep-blue/hydra, manually on i-mac (or launchd):

```
manual = imperatively installed
         apt:  apt-mark showmanual
         brew: brew leaves --installed-on-request
known  = union of this machine's active profile lists (common+apt+brew)

diff:
  candidates = manual − known   → "installed but not in dotfiles — add?"
  drift      = known − manual   → "declared but missing — package failed?"
  source     = opt/source confs vs binaries:
               stale  → git pkg local tag ≠ pkg_branch (run update.sh)
               missing → conf present, binary absent (build needed)
  fresh      = advisory staleness report (the single-user Renovate):
               Debian: `apt list --upgradable`; per declared pkg
               `apt-cache policy` → "newer in trixie-backports?" (then:
               add to opt/backports.txt or leave — declared decision);
               brew: `brew outdated`; source: git describe vs remote tags.
```

- Output: `~/dotfiles-review-$(hostname).md`, plus exit code for drift.
- **Per-machine review only** — names come from the same OS world, so no
  cross-OS name mapping is needed.
- Review cadence: add/remove from profile lists; the diff converges to empty.
- This is the loop that prevents the next drift spiral (the dotnix disease).

## Phases

### Phase 1 — Baseline snapshot ✅ (2026-09)
✅ deep-blue snapshot in notes/. hydra = blank slate (no snapshot needed);
i-mac snapshot deferred until online.

### Phase 2 — Structure ✅ implemented (commit ce30f9a)
Profiles, hosts/, apt-sources, ssh config, source layer, review loop, engine.
See layout above.

### Phase 3 — Package triage ✅ implemented
Legacy lists retired (debianPkgs/common.txt/Brewfile); classified per tier incl.
ecosystem-manager-first rule.

### Phase 4 — Source layer ✅ implemented
opt/source (nvim pinned v0.12.5, sha256 on all tarballs, pkg_bin checks).

### Phase 5 — Review loop ✅ implemented
review_packages.sh + weekly systemd timer (profiles/base/services) + parity
--packages. First drift report on deep-blue produced 2026-09.

### Phase 6 — Rollout
- deep-blue: relinked + parity ✅ (2026-09); full package install + timer
  enable pending (run ./install.sh with sudo; needs the .bak cleanup from
  the apt-sources section earlier).
- hydra: blank-slate install via USB tarball — pending (see hosts/README).
- i-mac: pending (snapshot + brew rollout when online).
- dotnix: delete when hydra is up.

### Phase 7 — Optional guardrails
Clean-room test: run install.sh --check in a trixie docker container before
big changes (cheap CI).

## Decisions (locked)
- **Wayland stack retired** (2026-09): `configs/sway`, `configs/waybar`, `configs/wofi`
  deleted. Desktop profile = dwm/X11 (suckless + rofi) only. `configs/rofi` stays.
- **Package classification locked** (2026-09, see section above): source set =
  {neovim, tmux}; mpd/rmpc → desktop profile.

## Open decisions (triage phase, no structural impact)
- `theme/` (colors, remote-hosts) — universal or desktop?
- `mpd`/`rmpc` — desktop (hydra) or does deep-blue run a music server?
- `virt-manager` (GUI) → desktop, while qemu/libvirt stay base?
- `vim` vs `nvim` — keep both in base or retire vim?

## Steps we were missing (2026-09 gap review)

Walked the full lifecycle (fresh install → daily use) against the plan.
These were absent:

1. **Secrets provisioning — DECIDED: manual + presence check** (2026-09).
   `envs/api_keys` stays out of git forever. Documented copy step in
   `hosts/README` + install.sh verifies the file exists and warns when
   missing (never blocks). Trade-off accepted: dead disk loses keys.
2. **Git identity + SSH + gh auth not wired** — `scripts/debian/setup_github.sh`
   exists but install.sh never calls it. Fresh machines get no
   user.email/user.name, no SSH key, no gh login → repo itself can't be
   pushed. Wire into base adapter (Phase 2/3).
3. **Per-host service enablement** — nothing enables services: sshd, tailscale
   up (needs auth!), postgres/redis on deep-blue; bluetooth/tlp on hydra.
   Add `hosts/<h>/services` (unit names to enable) + adapter step.
4. **~/.ssh/config + host aliases** — none in repo; tailscale names are
   `deep-blue`, `hydra`, `imac-de-carlos`. Commit a base `configs/ssh/` with
   aliases + proxy\(tailscale) template so `ssh hydra` works everywhere.
5. **dotpi provisioning** — check_parity verifies links, but nothing CLONES
   `~/dotpi` (separate repo: settings, trust, extensions) on a fresh machine.
   Add bootstrap step: clone + init submodules (Phase 2).
6. **Clean-room test** — no CI: run `install.sh --check` in a trixie docker
   container as the Phase 2/3 acceptance (catches missing sudo/git/hostname
   assumptions cheaply; container build is one Dockerfile).
7. **hosts/ mapping doc** — machine → tailscale name → profile → notes
   (hostnames/ i-mac = `imac-de-carlos`) + `hosts/README` so fresh installs
   know what to name the box and which flag to pass.

## Rules of engagement (post-mortem from dotnix)
1. One package manager per OS. No nix layer.
2. Lists are the single source of truth for packages; imperative installs are
   reviewed weekly, not forbidden.
3. Configs are shared by default; host divergence lives in profile dirs, not
   forks of config files.
4. GUI/desktop-only packages must never appear in base.