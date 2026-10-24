# dotfiles

One repo, three machines, three profiles. Debian 13 (deep-blue server, hydra
laptop) + macOS (i-mac). No nix — one package manager per OS, one source of
truth per tool.

## Quick start

```bash
git clone --recurse-submodules git@github.com:EduardoNeville/dotfiles ~/dotfiles
cd ~/dotfiles
./install.sh                          # full: sources → packages → configure → parity
./install.sh --profile base,desktop   # hydra-style (or just name the host right)
./install.sh --check                  # parity only
```

USB tarball (with submodules) for offline hosts: see `hosts/README.md`.

## Layout

```
profiles/base/      packages.common|apt|brew — what EVERY machine gets
profiles/desktop/   packages.apt + configs — hydra only (dwm, audio, bluetooth)
hosts/<hostname>/   per-host packages + apt-sources + PROFILE declaration
apt-sources/        debian.sources (trixie + updates + security + backports)
configs/            universal dotfiles, symlinked to ~/.config (ssh → ~/.ssh)
opt/                backports.txt, casks/taps, cargoPkgs, opt/source (nvim/tmux builds)
scripts/            engine (lib/), adapters (debian|macos), check_parity.sh, review_packages.sh
deprecated/         retired installers (not wired into install.sh) — see its README
```

`install.sh` is the only install entry point. Everything it runs is either
`scripts/lib/*`, `scripts/<os>/configure_system.sh`, or a
`profiles/<profile>/scripts/*` helper.

The pi agent config is **not** tracked here. It lives in its own repo
([`dotpi`](https://github.com/EduardoNeville/dotpi)), which the installer clones
to `~/dotpi` and then delegates to (`scripts/lib/link.sh` → `dotpi/install.sh`).
That repo owns `~/.pi/agent/*` and the pi extensions; this one only bootstraps it.

### Desktop layer (profile: `desktop`)

On top of dwm/audio/bluetooth, the desktop profile ships display defaults tuned
for the T480's ~250-nit panel (`install.sh` applies all of it; details and
measurements in `notes/backlight-legibility-plan.md`):

- `profiles/desktop/scripts/light.sh` + `lut.py` — one 0–130% brightness scale.
  ≤100% is the real backlight; >100% adds a midtone LUT curve, because the
  panel's 100% duty *is* the hardware ceiling. Bound to the brightness keys.
- `profiles/desktop/configs/Xresources` — `Xft.dpi: 110` for a 157dpi panel
  (merged by `dwm-session.sh` before dwm starts; `dwm-session.sh` also re-applies
  the saved brightness after picom, which would otherwise reset the LUT).
- `configs/fontconfig/fonts.conf` — subpixel/hinting, for GTK3 which ignores
  the X resources above.
- `setup_legibility.sh` — install-time dependency check plus the per-profile
  Firefox page scale (1.15), since Firefox profiles cannot be symlinked.

A fresh desktop install starts at **120%** (`LIGHT_DEFAULT`), i.e. hardware
100% + curve. Change it with the brightness keys, `light.sh set N`, or by
exporting `LIGHT_DEFAULT` before `install.sh`.

## Rules (locked)

1. **Tier ladder** per tool: stable → declared backports → vendor repo →
   vendor .deb → source (`opt/source`, frozen at nvim+tmux) →
   ecosystem managers (cargo/npm/bun/pipx) **win over apt when they exist**.
2. **One source per tool.** Platform divergence lives in profile lists, never
   forks of config files.
3. **Everything declared.** The weekly review
   (`~/dotfiles-review-$(hostname).md`, systemd timer on Debian) diffs
   imperatively-installed packages against the lists — candidates and drift
   are decisions you make, not surprises at 3am.
4. **Secrets never in git** (`envs/`, api keys) — manual copy + presence check.
5. **deb822 only** for apt sources; repo basename == deployed basename.

## Machines

| machine | profile | notes |
|---|---|---|
| deep-blue | base | DL360 G9 headless; HP tooling + postgres/redis per-host |
| hydra | base desktop | T480, dwm + audio + bluetooth |
| i-mac | base | brew |

See `hosts/README.md` for the full inventory and fresh-install runbook.
Design history: `notes/redesign-plan.md`.