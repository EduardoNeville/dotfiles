# fast-syntax-highlighting themes (dark / light)

Custom F-Sy-H themes matching the shared dotfiles palettes:

- `dark.ini`  — Night Owl (matches the wezterm dark scheme + tmux dark)
- `light.ini` — Catppuccin Latte (matches the wezterm light scheme + tmux light)

## Wiring

`~/.config/f-sy-h` is symlinked to this directory:

```sh
ln -sfn ~/dotfiles/configs/zsh-conf/themes/f-sy-h ~/.config/f-sy-h
```

`configs/zsh-conf/theme-zsh.zsh` switches between them automatically on every
prompt by calling `fast-theme -q CONFIG:dark` / `fast-theme -q CONFIG:light`
when `~/.local/state/theme` changes.

## Why light.ini exists

The stock F-Sy-H default theme is designed for dark terminals and uses
dark-background styles (`bg:blue`, `bg:18`, ...). On a light terminal the
terminal's default foreground (dark text) renders on those dark backgrounds —
the "background same colour as the text" unreadable-text bug. `light.ini`
replaces every dark `bg:` style with a light-gray background (`#ccd0da`) and
explicit dark foregrounds.

## Manual switching (no prompt reload)

```sh
fast-theme CONFIG:light   # or CONFIG:dark
```

The current line re-highlights on the next keystroke (F-Sy-H caches per
buffer). The prompt hook handles everything automatically.
