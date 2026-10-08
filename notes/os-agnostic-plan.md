# OS-Agnostic Dotfiles — Implementation Plan

Goal: one source of truth, one linker, one entrypoint. macOS and Debian (plus future
Void/Fedora) differ only in package names and system services. Every config file is
shared; platform divergence lives *inside* config files as runtime checks, never as
duplicate files.

## Design: 3 layers

```
Layer 1  CONTENT (100% OS-agnostic)
  configs/*            all dotfiles (already shared via symlinks)
  ~/dotpi              pi agent config (already portable POSIX)
  opt/common.txt       tool names identical on brew/apt (new)
  opt/macos.txt        brew-only: casks, fonts
  opt/debian.txt       apt-only: libs, firmware

Layer 2  ENGINE (OS-agnostic, pure bash)
  scripts/lib/os.sh        detect_os; pkg_install <name>; has <cmd>
  scripts/lib/link.sh      ALL symlinking (moved out of debian script)
  scripts/lib/packages.sh  read lists, loop pkg_install

Layer 3  ADAPTERS (thin, per-OS, ~50 lines each)
  scripts/macos/configure_system.sh   brew casks, defaults, fonts via brew
  scripts/debian/configure_system.sh  apt libs, systemd units, audio, suckless
```

## Key rules

1. **Symlink everything, link nothing twice.** `link.sh` is the only place that
   creates a symlink. Same backup-then-link semantics that exist today.
2. **Package lists split by availability, not by OS.** `common.txt` is installed on
   every OS through the dispatcher; `macos.txt`/`debian.txt` hold what only one OS
   can/should have. Name mismatches (e.g. `git-delta` vs `delta`) go in
   `opt/overrides/<os>.txt` as `brew-name|apt-name` pairs — keep this file small;
   prefer adding to common only when names match.
3. **Divergence inside configs, not between configs.** Example (already the pattern):
   wezterm/zsh check `uname`/`os.execute` at runtime. If macOS and Debian need
   different settings, it's one `if` in one file, not `wezterm.macos.lua`.
4. **Fail soft on OS-specific steps.** Every adapter step guards with `has`/`uname`
   (the fc-cache/usermod lesson). Engine never assumes Linux.

## Phases

### Phase 1 — Extract the engine (no behavior change)
- Create `scripts/lib/link.sh`: move `link_dotfiles`, `link_zsh_config`,
  `link_gitconfig`, `link_pi_config`, `create_common_directories` out of
  `scripts/debian/configure_system.sh` verbatim.
- `configure_system.sh` sources the lib and keeps only its adapter parts
  (groups, fonts, systemd).
- **Acceptance:** run on Debian → byte-identical symlinks; `check_parity.sh` green
  on both machines.

### Phase 2 — macOS entry point
- New `scripts/macos/configure_system.sh`: sources `lib/link.sh`, plus
  `brew bundle` casks/fonts and `chsh`. Nothing else.
- `full_install.sh` dispatch now really goes to `scripts/$OS/configure_system.sh`
  (the fallback-to-debian path dies).
- **Acceptance:** `bash full_install.sh` on a clean macOS account produces the same
  links as the hand-made ones today (verify with `check_parity.sh`).

### Phase 3 — Package unification
- Split `opt/debianPkgs` + `opt/Brewfile` into `common.txt` / `macos.txt` /
  `debian.txt` / `overrides/`.
- `scripts/lib/packages.sh`: for each name in common → `pkg_install` (brew / apt -
  install / xbps). Continue-on-fail, log failures, summary at end.
- Add `check_parity.sh --packages`: verify every name in `common.txt` resolves on
  both OSes (cross-check overrides) — this is what catches the next `starship` gap.
- **Acceptance:** `--packages` green on both machines.

### Phase 4 — Single entrypoint + retirement
- Root `install.sh`: detect OS → install packages → run adapter → run
  `check_parity.sh`. Flags: `--no-packages`, `--links-only`, `--check`.
- `full_install.sh` becomes a deprecated shim that prints "use ./install.sh" and
  execs it. Delete after both machines migrate.
- **Acceptance:** one command on a fresh macOS and a fresh Debian yields identical
  `check_parity.sh` output (modulo `macos.txt`/`debian.txt` extras).

### Phase 5 — Guardrails (optional, cheap)
- GitHub Actions: shellcheck all scripts; run `install.sh --check` in a Debian
  container. macOS CI is not worth it — the check script is the local guard.
- launchd/cron on each machine: weekly `check_parity.sh` → drift alarm.

## What stays OS-specific (on purpose)

| Concern | macOS | Debian |
|---|---|---|
| Services | launchd (none needed) | systemd units, pipewire |
| Desktop/WM | — (Aqua) | sway/dwm, waybar, rofi, wofi, dunst |
| Audio | CoreAudio | PipeWire setup script |
| Fonts | brew cask | fc-cache |
| Package mgr | brew | apt |

These live only in adapters; no engine code branches on OS except `pkg_install`.

## Effort

Phase 1–2: ~1 hour, mechanical. Phase 3: ~2 hours (list triage is the real work).
Phase 4: ~1 hour. Phase 5: ~30 min.
