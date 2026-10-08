# hosts — machine inventory

| tailscale name | hostname  | OS          | profile            | notes |
|---|---|---|---|---|
| deep-blue      | deep-blue | Debian 13   | base (default)     | DL360 G9, headless server. HP tooling + postgres/redis in hosts/deep-blue/ |
| hydra          | hydra     | Debian 13   | base desktop       | hosts/hydra declares it |
| imac-de-carlos | imac      | macOS       | base (default)     | brew. hostname file only if profile ever changes |

Profile resolution order: `--profile` flag > `$PROFILE` env > `hosts/<hostname>` file > `base`.

## Setting up a fresh machine (blank disk, like hydra)

1. Install minimal Debian (or macOS) from the official ISO.
2. Give the machine its real hostname (`hostname <name>` as root, or during install).
3. Get the repo onto it:
   - USB: `tar xzf /media/<usb>/dotfiles.tar.gz -C ~ && mv dotfiles-master ~/dotfiles` (tarball includes submodules)
   - or network: `git clone --recurse-submodules git@github.com:EduardoNeville/dotfiles ~/dotfiles`
4. Secrets (manual by decision 2026-09): copy keys/API tokens in — `envs/api_keys`,
   `~/.ssh/id_ed25519`, pi/opencode tokens — NOT in git. `install.sh` warns when missing.
5. `cd ~/dotfiles && ./install.sh` — sudo password prompts expected; needs network.
   Desktop machine without a `hosts/<name>` file: `./install.sh --profile base,desktop`.
6. Log out/in (groups, shell). Register the printed SSH pubkey once at
   https://github.com/settings/ssh/new (key is auto-generated during install;
   gh auth auto-skips until then). `tailscale up`.
7. Verify: `./install.sh --check` → ✓ Parity OK; `scripts/check_parity.sh --packages`.

Weekly (automatic on Debian via `profiles/base/services/review-packages.timer`):
review `~/dotfiles-review-$(hostname).md`, add candidates to the right profile
list, drop drift by running `./install.sh`. That file IS the update process.