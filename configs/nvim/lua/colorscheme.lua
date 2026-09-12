--- Colorscheme config
---
--- Dynamically switches between:
---   - Dark mode:  synthweave-transparent
---   - Light mode: catppuccin-latte
---
--- Theme detection via ~/.local/state/theme (written by wezterm's toggle).
--- On FocusGained, re-checks state file and switches if needed.

require("theme-sync").init()
