# deprecated/

Retired code, kept for history. **Nothing here is wired into `./install.sh`.**

| File | What it was | Replaced by |
|---|---|---|
| `full_install_old.sh` | Pre-2026-09 monolithic installer: menu-driven, per-OS branches, sourced `installer.sh` | `install.sh` → `scripts/lib/{os,link,packages,apt_sources}.sh` → `scripts/<os>/configure_system.sh` |
| `installer.sh` | Helper functions only `full_install_old.sh` used (nix, one-off apt installs, brew) | profile package lists (`profiles/*/packages.*`), `opt/*` |

There is exactly **one** install entry point: `../install.sh`.

The 7-line `full_install.sh` forwarder that used to sit in the repo root was
deleted in 2026-10. It only translated `--full`/`--unattended` and `exec`'d
`./install.sh`; `git show <rev>:full_install.sh` recovers it if a machine or a
note still calls it. Scripts and hooks should call `./install.sh` directly.

Historical plans that describe the retirement:
`../notes/os-agnostic-plan.md`, `../notes/redesign-plan.md`.
