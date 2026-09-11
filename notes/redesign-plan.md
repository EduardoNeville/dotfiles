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
├── hosts/<hostname>            # optional, e.g. hosts/hydra:  PROFILE="base desktop"
│                               #   plus hosts/<hostname>/packages.{apt,brew} for per-host extras
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
    ├── debs/                    # local .deb pins: install.sh runs `apt install -y ./debs/*.deb`
    ├── source/                  # SOURCE-BUILD manifests+scripts (formalized ~/pkgs, see section below)
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

## Source-build layer (Tier 3 — the cure for outdated apt)

Per-tool decision ladder (applied during triage, per package):
1. apt version acceptable? → `packages.*` list.
2. Vendor ships a current .deb (docker-ce, gh, neovim releases)? → `opt/debs/`.
3. Otherwise → source build via `opt/source/` — keep the list tiny (today:
   nvim, tmux + their private deps libevent, bison).

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
about. For 4 pinned tools, the formalized prefix system is the smallest thing
that works.

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
```

- Output: `~/dotfiles-review-$(hostname).md`, plus exit code for drift.
- **Per-machine review only** — names come from the same OS world, so no
  cross-OS name mapping is needed.
- Review cadence: add/remove from profile lists; the diff converges to empty.
- This is the loop that prevents the next drift spiral (the dotnix disease).

## Phases

### Phase 1 — Baseline snapshot (data first)
✅ deep-blue done (2026-09): `notes/packages-deep-blue-2026-09.md` (300 manual pkgs).
Key finds: docker-ce family installed but `debianPkgs` declares `docker.io`;
HP server tooling (amsd/hponcfg/ssacli/storcli/hpilo/ipmitool) is deep-blue-only
→ motivated the `hosts/<hostname>/packages.*` layer.
⬜ hydra: `cd ~/dotfiles && apt-mark showmanual | sort > notes/packages-hydra-2026-09.md`
⬜ i-mac: `brew leaves --installed-on-request | sort > notes/packages-imac-2026-09.md`

### Phase 2 — Structure (engine, no behavior change to packages, ~2 h)
- Create `hosts/`, `profiles/base|desktop/`, move desktop configs + debian
  desktop scripts into `profiles/desktop/`.
- Make `install.sh`, `link.sh`, `check_parity.sh` profile-aware.
- **Acceptance:** `install.sh --check` identical output on all 3 machines
  (desktop configs ignored on deep-blue).

### Phase 3 — Package triage (the real work, ~3 h)
Split `debianPkgs` (191 lines) → `base/packages.apt` + `desktop/packages.apt`
using the Phase 1 snapshots; split `Brewfile` → `base/packages.brew` + casks +
taps; grow `packages.common`. Kill `debianPkgs`, `Brewfile`, `common.txt`.
Also run the 3-tier ladder per package (apt-vs-deb-vs-source) using the
snapshots — this is where nvim/tmux/… get classified.
- **Acceptance:** `check_parity.sh --packages` green on all 3 machines.

### Phase 4 — Source layer (~2 h)
Migrate `~/pkgs` manifests+scripts into `opt/source/`, add `pkg_sha256`,
pin git branches to tags, wire `ensure_source_pkgs` into the apt adapter.
- **Acceptance:** hydra reproduces deep-blue's nvim+tmux from the repo
  (`build.sh` + `update.sh` work, parity green).

### Phase 5 — Review loop (~1 h)
`review_packages.sh` + `configs/services/review-packages.{service,timer}` on the
Debians; wire the first review rounds (Phase 1 confirmations). `check_parity
--packages` covers drift; review covers candidates.
- **Acceptance:** weekly timer produces a review file; first round applied.

### Phase 6 — Rollout in place (~1 h + machine time)
deep-blue first (base), then hydra (base+desktop), then i-mac (brew). Verify
parity, delete `dotnix` (archive tag first), delete `full_install.sh` shim,
rewrite README around profiles.

## Decisions (locked)
- **Wayland stack retired** (2026-09): `configs/sway`, `configs/waybar`, `configs/wofi`
  deleted. Desktop profile = dwm/X11 (suckless + rofi) only. `configs/rofi` stays.

## Open decisions (triage phase, no structural impact)
- `theme/` (colors, remote-hosts) — universal or desktop?
- `mpd`/`rmpc` — desktop (hydra) or does deep-blue run a music server?
- `virt-manager` (GUI) → desktop, while qemu/libvirt stay base?
- `vim` vs `nvim` — keep both in base or retire vim?

## Rules of engagement (post-mortem from dotnix)
1. One package manager per OS. No nix layer.
2. Lists are the single source of truth for packages; imperative installs are
   reviewed weekly, not forbidden.
3. Configs are shared by default; host divergence lives in profile dirs, not
   forks of config files.
4. GUI/desktop-only packages must never appear in base.