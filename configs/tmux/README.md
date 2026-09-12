# Tmux Configuration for SSH/Tailscale

A sleek, modern tmux configuration optimized for managing remote servers via Tailscale VPN.

## Features

- **Powerline-style status bar** with synthwave color scheme
- **Git branch display** - Shows current branch in status bar
- **Tailscale integration** - Shows connection status in status bar
- **SSH indicator** - Shows when connected via SSH
- **SSH shortcuts** - Quick SSH connections to hosts
- **Vim-style keybindings** - Familiar navigation
- **Session management** - Create and rename sessions easily
- **True color support** - Full 256-color terminal support

## Color Scheme

Matches your existing dotfiles theme:
- Blue (#0969da) - Primary accent
- Light Blue (#45aeff) - Secondary accent
- Cyan (#0ae4a4) - Tailscale/t Success indicators
- Pink (#f0268f) - Active window highlight, git branch
- Yellow (#f1d751) - SSH indicator

## Key Bindings

### Prefix Key
- `Ctrl+Space` - Prefix key (instead of Ctrl+B)

### Windows & Panes
- `prefix + c` - Create new window
- `prefix + v` - Split window horizontally
- `prefix + s` - Split window vertically
- `prefix + x` - Kill pane
- `prefix + X` - Kill window
- `prefix + r` - Rename window

### Navigation (Vim Style)
- `prefix + h/j/k/l` - Navigate panes
- `prefix + H/J/K/L` - Resize panes
- `prefix + n/p` - Next/previous window
- `prefix + Tab` - Last window
- `prefix + </>` - Move window left/right

### SSH & Tailscale
- `prefix + S` - SSH to host (opens prompt)
- `prefix + Shift+S` - SSH to host (in split)
- `prefix + T` - Show Tailscale status (auto-updating)
- `prefix + N` - Show network connections

### Sessions
- `prefix + C` - Create new session (prompts for name)
- `prefix + $` - Rename current session
- `prefix + Shift+Left/Right` - Switch to previous/next session
- `prefix + L` - List all sessions (tree view)
- `prefix + d` - Detach from session
- `prefix + P` - Fuzzy session picker

### Utilities
- `prefix + R` - Reload tmux config
- `prefix + ?` - Show help

## Status Bar

### Left Side
- **Session name** (blue background)
- **Hostname** (light blue)
- **Git branch** (pink - shows current git branch in repo)

### Center
- **Window list** with powerline separators
- Active window highlighted in pink
- Zoom indicator (󰊓) when pane is zoomed

### Right Side
- **SSH indicator** (yellow - shows when connected via SSH)
- **Tailscale status** (green when connected, red when offline)

## Tailscale Integration

The status bar automatically checks if Tailscale is connected by running:
```bash
tailscale status --json | jq -r '.Self.Online'
```

- 󰱠 **CONNECTED** - Green indicator when online
- 󰅙 **OFFLINE** - Red indicator when offline

## Customization

### Adding SSH Hosts
Edit the SSH bindings in `tmux.conf`:
```bash
# Add predefined hosts
bind-key h new-window -n "home-server" "ssh user@home-server.tailnet.ts.net"
bind-key w new-window -n "work-server" "ssh user@work-server.tailnet.ts.net"
```

### Modifying Colors
Colors are defined throughout the config. Look for hex values like:
- `#0969da` - Primary blue
- `#45aeff` - Light blue
- `#f0268f` - Pink/Magenta
- `#0ae4a4` - Cyan
- `#65ff87` - Green
- `#f1d751` - Yellow

### Network Interface
The status bar automatically detects the default network interface. To use a specific interface, modify:
```bash
# Change eth0 to your interface
set -ga status-right "... /sys/class/net/eth0/statistics/rx_bytes ..."
```

## Prerequisites

- tmux 3.0+ (for true color support)
- zsh (configured as default shell)
- Nerd Fonts (for status icons)
- jq (for Tailscale JSON parsing)
- Optional: ifstat or similar for network monitoring

## Installation

The config is automatically symlinked when you run:
```bash
bash scripts/debian/configure_system.sh
```

Or manually:
```bash
ln -s ~/dotfiles/configs/tmux ~/.config/tmux
```

## Usage Tips

1. **Start a new session**: `tmux new -s server-session`
2. **Attach to existing**: `tmux attach -t server-session`
3. **List sessions**: `tmux ls`
4. **Quick SSH**: Press `Ctrl+Space` then `S`, type hostname

## Troubleshooting

**Colors not showing correctly:**
- Ensure your terminal supports true color
- Check `$TERM` is set to `tmux-256color` or `xterm-256color`

**Icons not displaying:**
- Install Nerd Fonts: https://www.nerdfonts.com/
- WezTerm uses: Fira Code Nerd Font or similar

**Tailscale status not updating:**
- Ensure `jq` is installed: `sudo apt install jq`
- Check Tailscale is running: `tailscale status`

## Integration with Starship

The tmux status bar complements your Starship prompt:
- Tmux shows system-level info (hostname, network, load)
- Starship shows directory, git, and language info
- Together they provide complete context

## License

Same as dotfiles repository - MIT License
