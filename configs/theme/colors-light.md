# Light Theme Palette (Catppuccin Latte-inspired)

This document is the single source of truth for the light mode color palette
shared across all tools (wezterm, tmux, opencode, neovim).

Background: off-white `#FAFAFA` for reduced eye strain compared to pure white.
Foreground: near-black `#1A1A2E` for maximum contrast.

## ANSI / Terminal Colors

| Name    | Hex       | Catppuccin Equivalent | Usage                    |
|---------|-----------|-----------------------|--------------------------|
| Black   | `#2D3748` | Surface2              | Dark UI elements         |
| Red     | `#D20F39` | Red                   | Errors, deletions        |
| Green   | `#40A02B` | Green                 | Success, additions       |
| Yellow  | `#DF8E1D` | Yellow                | Warnings, strings        |
| Blue    | `#1E66F5` | Blue                  | Links, active elements   |
| Magenta | `#EA76CB` | Pink                  | Keywords, highlights     |
| Cyan    | `#179299` | Teal                  | Info, types              |
| White   | `#F5F5F9` | Surface0              | Light UI elements        |

## Core Interface Colors

| Role               | Hex       | Usage                          |
|--------------------|-----------|--------------------------------|
| Background         | `#FAFAFA` | Main canvas                    |
| Foreground         | `#1A1A2E` | Primary text                   |
| Cursor             | `#1E66F5` | Text cursor (blue for vis.)    |
| Selection BG       | `#BEE3F8` | Selected text background       |
| Selection FG       | `#1A1A2E` | Selected text color            |
| Comment / Subtext  | `#6C6F85` | Comments, secondary text       |
| Line Numbers       | `#9CA0B0` | Gutter line numbers            |

## UI Chrome Colors

| Role              | Hex       | Usage                          |
|-------------------|-----------|--------------------------------|
| Status BG         | `#FAFAFA` | Status bar background          |
| Status FG         | `#1A1A2E` | Status bar text                |
| Active Accent     | `#1E66F5` | Active tab, borders, highlights|
| Inactive BG       | `#E6E9EF` | Inactive tabs, segments        |
| Inactive FG       | `#9CA0B0` | Inactive tab text              |
| Mode Accent       | `#8839EF` | Mode indicator (tmux mode)     |
| Warning           | `#DF8E1D` | Warnings, SSH indicator        |
| Success           | `#40A02B` | Success, connected indicators  |
| Pane Border       | `#E6E9EF` | Inactive pane borders          |
| Active Border     | `#1E66F5` | Active pane border             |

## Tool-Specific Notes

### Wezterm
- Light mode: use `light_colors` table (inline colors) instead of named scheme
- Dark mode: use `"Night Owl (Gogh)"` built-in scheme
- Tab bar colors are set via `config.colors.tab_bar`
- Window frame bg = `#FAFAFA`

### Tmux
- Dark-mode defaults are in `tmux.conf`; light mode is applied by
  `tmux_theme_sync.sh` which reads `~/.local/state/theme`
- Status-left/right/window-status-format are fully redefined in the script
- The script never writes to the state file (wezterm owns it)

### Neovim
- Dark mode: `synthweave-transparent`
- Light mode: `catppuccin-latte` (catppuccin/nvim with flavour = "latte")
- Lualine: dark → `custom_ayu`, light → `catppuccin` (auto-detects latte)
- Barbecue winbar: adapts via ColorScheme autocmd

### Opencode
- Theme colors defined in `opencode.jsonc` `"theme"."light"` section
- Background: `#FAFAFA`, foreground: `#1A1A2E`
- Sync mechanism: `"sync_with_shell": true` reads `~/.local/state/theme`
