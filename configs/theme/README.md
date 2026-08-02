# Theme propagation layer

Keeps the theme (`light` / `dark`) in sync between Wezterm, tmux, and remote
SSH hosts via a single shared state file:

    ${XDG_STATE_HOME:-~/.local/state}/theme

## Scripts (`configs/theme/scripts/`)

| Script | Purpose |
|---|---|
| `theme_state.sh` | Read/write/toggle the shared state file (`get`, `set`, `toggle`). |
| `tmux_theme_sync.sh` | Apply the state file to tmux. `tmux set -g` / `setw -g` are server-wide, so this works from a NON-tmux shell and updates every session; if no tmux server is running it logs a note and exits 0. |
| `propagate_state.sh` | The main entry point (Wezterm calls this on toggle). Writes the state locally, syncs local tmux, then pushes the state to every host in `~/.config/theme/remote-hosts` in the background. Timestamps everything into `~/.local/state/theme-propagate.log`. |
| `setup_theme_remotes.sh` | One-time setup: creates `~/.config/theme/remote-hosts` (default `deep-blue`) and validates connectivity to every host. |
| `verify_theme_sync.sh` | End-to-end check: flips the theme through `propagate_state.sh`, asserts tmux global options changed on every reachable host, reports `theme-sync.log` growth (pi extension evidence), restores the original theme. |

## How the pieces fit

1. Wezterm's `toggle_theme()` calls `propagate_state.sh light|dark`.
2. `propagate_state.sh` writes `~/.local/state/theme`, syncs the local tmux
   server (server-wide options → all sessions), then for each host in
   `~/.config/theme/remote-hosts` runs, in the background:
   `mkdir -p ~/.local/state && echo <theme> > ~/.local/state/theme && bash ~/dotfiles/configs/theme/scripts/tmux_theme_sync.sh`
3. The remote `tmux_theme_sync.sh` applies the theme to that host's tmux.
4. The pi extension (`configs/pi/extensions/theme-sync/`) watches the state
   file and calls `ctx.ui.setTheme`, appending to `~/.local/state/theme-sync.log`.

## Logging

All propagation-layer events (local writes, tmux sync, per-host
attempts/failures) are appended with timestamps to:

    ${XDG_STATE_HOME:-~/.local/state}/theme-propagate.log

Wezterm invokes `propagate_state.sh` non-interactively with zero feedback, so
this log is the primary way to see what happened:

    tail -f ~/.local/state/theme-propagate.log

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

## tmux.conf integration

`configs/tmux/tmux.conf` already wires this in:

- `set-hook -g client-focus-in "run-shell 'bash ~/dotfiles/configs/theme/scripts/tmux_theme_sync.sh'"`
  re-syncs the theme when a window gains focus (catches Wezterm toggles).
- A `run-shell` at load time applies the current theme when the config loads.
- `bind Y` runs `tmux_theme_sync.sh toggle`.

Palettes live ONLY in `tmux_theme_sync.sh` (light + dark); tmux.conf keeps the
dark palette as a static default and must not duplicate both palettes.
