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
```

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