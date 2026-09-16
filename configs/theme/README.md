# Theme propagation layer

One state file is the source of truth for `light` / `dark`:

    ${XDG_STATE_HOME:-~/.local/state}/theme

Every surface reads that file; only one script ever writes it.

## Consumers

| Surface | How it picks up the theme |
| dwm (bar, borders) | `reloadtheme()` on SIGWINCH — the handler only sets a flag; `run()` does the Xlib work (Xlib is not async-signal-safe, and calling it from the handler deadlocks dwm) |
| lightdm login + light-locker lock screen | `greeter_theme.sh` rewrites slick-greeter's config (wallpaper, logo, GTK theme) via a symlink into the state dir — root-free |
| Wezterm | applies on start; re-reads the file on the status tick (`update-right-status`, 1s) |
| tmux (local + remote) | `tmux_theme_sync.sh` applies server-wide options (works from outside tmux) |
| Neovim | `lua/theme-sync.lua` — libuv `fs_event` watcher on the file, `FocusGained` fallback |
| pi TUI | `~/dotpi/extensions/theme-sync` — `fs.watch` on the file's directory |
| zsh: starship, fzf, autosuggestions, f-sy-h | `configs/zsh-conf/theme-zsh.zsh` precmd hook |
| remote hosts | `propagate_state.sh` writes the file over SSH, then runs their `tmux_theme_sync.sh` |
| lightdm login + light-locker lock screen | `greeter_theme.sh` rewrites `slick-greeter.conf`; `/etc/lightdm/slick-greeter.conf` is a symlink to it (`setup_lightdm.sh`), so no root per toggle |
| Firefox + GTK apps | `gtk_theme.sh` writes the GSettings appearance (`color-scheme`, `gtk-theme`) — the only system signal available without a DE or an xdg-desktop-portal. Firefox keeps the System theme and follows it for chrome and `prefers-color-scheme` |

The palette itself is documented in `colors-light.md`; dark values live next to
each consumer (they are not generated from one file — see "Why not one palette
generator" below).

## Trigger

One command toggles everything:

    bash ~/dotfiles/configs/theme/scripts/propagate_state.sh toggle

It is bound in two places:

- **dwm** (`config.h`): `Ctrl+Shift+Y`, global — dwm grabs the key, so it works
  no matter which window has focus. This is the primary binding on hydra.
- **Wezterm** (`wezterm.lua`): `Ctrl+Shift+Y` as well, for machines without dwm.
  wezterm never sees the key on hydra (dwm grabs it first), which is exactly why
  wezterm *follows the state file* instead of owning a flag of its own.

## Scripts (`configs/theme/scripts/`)

| Script | Purpose |
| `theme_state.sh` | Read/write/toggle the shared state file (`get`, `set`, `toggle`). |
| `tmux_theme_sync.sh` | Apply the state file to tmux. `tmux set -g` / `setw -g` are server-wide, so this works from a NON-tmux shell and updates every session; if no tmux server is running it logs a note and exits 0. Resolves the tmux **binary** explicitly (see the version note below). |
| `propagate_state.sh` | The entry point. Writes the state locally, signals dwm, syncs local tmux, then pushes the state to every host in `~/.config/theme/remote-hosts` in the background. Accepts `light`, `dark` or `toggle`. Timestamps everything into `~/.local/state/theme-propagate.log`. |
| `setup_theme_remotes.sh` | One-time setup: creates `~/.config/theme/remote-hosts` (default `deep-blue`) and validates connectivity to every host. |
| `verify_theme_sync.sh` | End-to-end check: converges every target, flips the theme through `propagate_state.sh`, asserts tmux's global status-style changed on every reachable host, reports `theme-sync.log` growth (pi extension evidence), restores the original theme. |
| `greeter_theme.sh` | Regenerate the slick-greeter config (login screen + light-locker lock screen) from the state file. Called by `propagate_state.sh` on every toggle. |
| `gtk_theme.sh` | Write the GSettings appearance (`org.gnome.desktop.interface` `color-scheme` + `gtk-theme`) so GTK apps and Firefox follow the theme. Called by `propagate_state.sh` (step 1f). Needs a D-Bus session bus; exits 1 with a note when dconf cannot be written. |
| `dwm_bar_probe.py` | Desktop-only check: reads the actual pixels of dwm's bar and asserts they match the state file (`--expect light|dark`). This is what proves the SIGWINCH reload path works. |

## How the pieces fit

1. `propagate_state.sh toggle` reads the state file, inverts it and writes it.
2. It signals the running dwm (`pkill -WINCH -x dwm`). SIGWINCH is used on
   purpose: its default disposition is *ignore*, so a dwm build that predates
   `reloadtheme()` ignores it — SIGUSR1 would terminate an unpatched dwm.
3. It rewrites the greeter config (`greeter_theme.sh`), so the lightdm login
   screen and light-locker's lock screen match.
4. It runs the local `tmux_theme_sync.sh` (no-op when no server is running).
5. For each host in `~/.config/theme/remote-hosts` it runs, in the background:
   `mkdir -p "${XDG_STATE_HOME:-$HOME/.local/state}" && echo <theme> > .../theme && bash ~/dotfiles/configs/theme/scripts/tmux_theme_sync.sh`
   — `$HOME`/`XDG_STATE_HOME` are expanded by the *remote* shell, so the host
   resolves its own paths.
6. Everything else (nvim, pi, zsh/starship) notices the file change on its own.

## tmux client/server version note

`/usr/bin/tmux` (3.5a) cannot drive a server started by the source build
(`~/pkgs/bin/tmux` → 3.7b): the client dies with **"server exited
unexpectedly"**, which earlier looked like "this tmux build cannot run a nested
tmux client from a run-shell" and led to the in-tmux `run-shell` hooks and
`bind Y` being deleted from `tmux.conf`. That diagnosis was wrong — it was a
client/server version mismatch.

`tmux_theme_sync.sh` (and the probes in `verify_theme_sync.sh`) therefore
resolve the binary explicitly — `$HOME/pkgs/bin/tmux`, then
`$HOME/.local/bin/tmux`, then `command -v tmux` — because neither a
wezterm-spawned shell nor `ssh host <cmd>` sources `~/.zshrc`, so PATH cannot be
trusted to give the same tmux as the running server.

## Logging
All propagation-layer events (local writes, dwm signal, tmux sync, per-host
attempts/failures) are appended with timestamps to:

    ${XDG_STATE_HOME:-~/.local/state}/theme-propagate.log

Keybindings invoke `propagate_state.sh` non-interactively with zero feedback, so
this log is the primary way to see what happened:

    tail -f ~/.local/state/theme-propagate.log

## Verifying

    bash configs/theme/scripts/verify_theme_sync.sh          # every configured host
    python3 configs/theme/scripts/dwm_bar_probe.py --expect light   # on the desktop

`verify_theme_sync.sh` first *converges* every target to the current theme, then
flips: a target whose tmux lagged its own state file would otherwise make the
flip a no-op and fail the assertion spuriously.

## One-time setup for a remote host

On the remote host (once):

    sudo tailscale up --ssh

From this machine (once per host):

    ssh-keyscan <host> >> ~/.ssh/known_hosts     # trust the host key
    ssh-copy-id <user>@<host>                    # allow plain-SSH fallback

Notes:

- If `ssh-keyscan <host>` produces nothing, the name may not resolve to a
  reachable address (e.g. a stale `/etc/hosts` entry). Fall back to the
  host's Tailscale IP: `ssh-keyscan $(tailscale ip -4 <host>) >> ~/.ssh/known_hosts`,
  or list the IP in `~/.config/theme/remote-hosts`.
- `setup_theme_remotes.sh` performs the connectivity validation and attempts
  the ssh-keyscan automatically.
- The plain-ssh fallback in `propagate_state.sh` uses
  `StrictHostKeyChecking=accept-new`, so a freshly-scanned host key is
  trusted without manual known_hosts edits.
- The remote host needs the dotfiles clone at `~/dotfiles` (the remote command
  calls its `tmux_theme_sync.sh`) — `./install.sh` on that machine.

## Known gaps

- The desktop wallpaper (`feh` in `dwm-session.sh`) is fixed at session start;
  only the greeter/lock wallpaper follows the theme. `assets/plain_light.png`
  exists if you want to hook `feh` up to the state file too.
- tmux applies its static dark palette at config load; a server started while
  the state is `light` shows dark until the next toggle. In-tmux `run-shell`
  hooks were deliberately not restored (an external apply is enough).
- `dmenu` keeps the compile-time dark palette (`dmenucmd` in `config.h`); it is
  launched on demand and would need runtime-generated arguments to follow.
- A host that is unreachable during a toggle keeps the stale theme until the
  next toggle; nothing pulls.

## Why not one palette generator

There is a single source of truth for *state* (the file), not for *colour
values*: wezterm, tmux, dwm, zsh and nvim each need their palette in their own
syntax, so a generator would have to own five renderers anyway. Keep the values
in the consumer that renders them, and keep `colors-light.md` as the reference
the light values are copied from.
