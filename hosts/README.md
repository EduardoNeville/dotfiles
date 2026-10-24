# hosts — machine inventory

| tailscale name | hostname  | OS          | profile            | notes |
|---|---|---|---|---|
| deep-blue      | deep-blue | Debian 13   | base (default)     | DL360 G9, headless server. HP tooling + postgres/redis in hosts/deep-blue/ |
| hydra          | hydra     | Debian 13   | base desktop       | hosts/hydra declares it |
| hiarcs         | hiarcs    | Debian 13   | base desktop       | laptop; hosts/hiarcs declares it |
| phalanx        | phalanx   | Debian 13   | base               | Xeon E5 server + Tesla P40; NVMe root, /boot on the HDD ESP |
| imac-de-carlos | imac      | macOS       | base (default)     | brew. hostname file only if profile ever changes |

Profile resolution order: `--profile` > `$PROFILE` env > `hosts/<hostname>` file > `base`.
Profile names must match a `profiles/<name>/` directory — `./install.sh` rejects
unknown ones instead of silently installing nothing.

## Setting up a fresh machine (blank disk, like hydra)

1. Install minimal Debian (or macOS) from the official ISO.
2. Give the machine its real hostname (`hostname <name>` as root, or during install).
3. Get the repo onto it — as your user, never with sudo:
   - USB: `tar xzf /media/<usb>/dotfiles.tar.gz -C ~ && mv dotfiles-master ~/dotfiles` (tarball includes submodules)
   - or network: `git clone --recurse-submodules git@github.com:EduardoNeville/dotfiles ~/dotfiles`
   - If an old checkout is root-owned (`ls -ld ~/dotfiles`), fix it first:
     `sudo chown -R $(id -u):$(id -g) ~/dotfiles` — otherwise every source build
     fails with `ld: cannot open output file ...: Permission denied`.
4. Secrets (manual by decision 2026-09): copy keys/API tokens in — `envs/api_keys`,
   `~/.ssh/id_ed25519`, pi/opencode tokens — NOT in git. `install.sh` warns when missing.
5. `cd ~/dotfiles && ./install.sh` — profile comes from `hosts/<hostname>/PROFILE`
   when it exists (create it, e.g. `base desktop` for laptops), otherwise `base`.
   One-off override: `./install.sh --profile base,desktop`.
   sudo password prompts expected; needs network.
6. Log out/in (groups, shell). Register the printed SSH pubkey once at
   https://github.com/settings/ssh/new (key is auto-generated during install;
   gh auth auto-skips until then). `tailscale up`.
7. Verify: `./install.sh --check` → ✓ Parity OK; `scripts/check_parity.sh --packages`.
8. Desktop machines: log in on tty1 — `~/.zprofile` execs `startx` →
   `~/.xinitrc` → `dwm-session.sh`, which starts dwm + slstatus + dunst + picom.

Weekly (automatic on Debian via `profiles/base/services/review-packages.timer`):
review `~/dotfiles-review-$(hostname).md`, add candidates to the right profile
list, drop drift by running `./install.sh`. That file IS the update process.
