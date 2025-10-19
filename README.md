# 🚀 Dotfiles - Fully Automated System Setup

[![OS Support](https://img.shields.io/badge/OS-Debian%20%7C%20Ubuntu%20%7C%20Void%20%7C%20Fedora%20%7C%20MacOS-blue)]()
[![Shell](https://img.shields.io/badge/Shell-Bash%20%7C%20Zsh-green)]()
[![WM](https://img.shields.io/badge/WM-dwm%20%7C%20i3%20%7C%20sway-orange)]()

> **Plug-and-play dotfiles system:** Drop this repo on a USB stick, plug into any machine, run one command, and watch your entire development environment install itself automatically.

---

## ⚡ Quick Start

```bash
# Clone the repository
git clone https://github.com/yourusername/dotfiles.git ~/dotfiles
cd ~/dotfiles

# Run the installer
bash full_install.sh

# Or for fully automated installation (no prompts)
bash full_install.sh --full

# Or for completely unattended (USB stick mode)
bash full_install.sh --unattended
```

**That's it!** Your entire system will be configured automatically.

---

## 🎯 What Gets Installed

### 🖥️ System Core
- **Window Managers:** dwm (custom build), i3, sway (Wayland)
- **Terminal Emulators:** alacritty, kitty, wezterm
- **Shell:** ZSH with plugins, starship prompt
- **Display Server:** X11 or Wayland support

### 🛠️ Development Tools
- **Languages:** Rust, Go, Node.js (via nvm), Python3, Java
- **Editors:** Neovim (with Lazy.nvim), Vim
- **Version Control:** Git, GitHub CLI, git-delta
- **Build Tools:** gcc, cmake, make, ninja
- **Containers:** Docker, docker-compose

### 🎨 Modern CLI Tools (Rust-based)
- `bat` - Better cat with syntax highlighting
- `eza` - Modern ls replacement
- `ripgrep` - Ultra-fast grep
- `fd` - Better find
- `zoxide` - Smarter cd
- `starship` - Cross-shell prompt
- `git-delta` - Beautiful git diffs
- `gitui` - TUI for git
- `btop` - System monitor
- `du-dust` - Better disk usage analyzer
- And many more...

### 🎵 Multimedia & Audio
- **Audio System:** PipeWire with WirePlumber
- **Bluetooth:** BlueZ with Blueman
- **Players:** mpv, vlc, cmus
- **Tools:** pavucontrol, helvum

### 🌐 Networking & Communication
- NetworkManager
- Firefox, Chromium
- Signal Desktop
- OpenVPN, WireGuard

### 📦 System Utilities
- Compression: 7zip, zip, tar, etc.
- File Systems: btrfs, ext4, ntfs, exfat
- Partitioning: gparted, parted
- Encryption: LUKS, cryptsetup

---

## 📋 Installation Modes

### 1️⃣ Interactive Mode (Default)
```bash
bash full_install.sh
```
Presents a menu to choose what to install. Perfect for customizing your setup.

### 2️⃣ Full Automated Mode
```bash
bash full_install.sh --full
```
Installs everything with minimal prompts. Best for complete system setup.

### 3️⃣ Unattended Mode (USB Stick Mode)
```bash
bash full_install.sh --unattended
```
Zero interaction required. Designed for USB stick deployment - plug in, run, walk away.

---

## 🗂️ Repository Structure

```
dotfiles/
├── full_install.sh              # Main installation script
├── configs/                     # Configuration files
│   ├── nvim/                   # Neovim configuration
│   ├── zsh-conf/              # ZSH configuration & plugins
│   ├── suckless/              # dwm, slstatus, st source
│   ├── dunst/                 # Notification daemon config
│   ├── rofi/                  # Application launcher
│   ├── sway/                  # Wayland compositor config
│   ├── waybar/                # Wayland status bar
│   ├── alacritty/             # Terminal config
│   ├── starship/              # Prompt config
│   └── .xinitrc               # X11 startup
├── scripts/                    # Installation scripts
│   └── debian/                # Debian/Ubuntu specific scripts
│       ├── setup_github.sh    # GitHub authentication
│       ├── install_suckless.sh # dwm, slstatus compilation
│       ├── install_rust_tools.sh # Rust & cargo packages
│       ├── install_nvm_node.sh # Node.js setup
│       ├── setup_audio.sh     # PipeWire audio
│       └── configure_system.sh # System configuration
├── opt/                        # Package lists
│   ├── debianPkgs             # Comprehensive Debian package list
│   ├── cargoPkgs              # Rust packages
│   ├── xbpsPkgs               # Void Linux packages
│   └── Brewfile               # MacOS packages
├── assets/                     # Wallpapers, icons, etc.
└── void-to-debian-packages.md # Package migration reference
```

---

## 🔧 Modular Scripts

Each component can be installed independently:

```bash
# Install and compile suckless tools (dwm, slstatus)
bash scripts/debian/install_suckless.sh

# Setup GitHub authentication
bash scripts/debian/setup_github.sh

# Install Rust and all cargo packages
bash scripts/debian/install_rust_tools.sh

# Setup Node.js via NVM
bash scripts/debian/install_nvm_node.sh

# Configure PipeWire audio system
bash scripts/debian/setup_audio.sh

# Link dotfiles and configure system
bash scripts/debian/configure_system.sh
```

---

## 🎨 Key Features

### ✅ Truly Automated
- **Zero manual intervention** in unattended mode
- Handles dependencies automatically
- Detects and adapts to different OSes
- Comprehensive error handling and logging

### ✅ GitHub Integration
- GitHub CLI authentication
- SSH key generation and setup
- Git configuration with sensible defaults
- Delta integration for beautiful diffs

### ✅ Window Manager Paradise
- **dwm** - Custom compiled with your patches
- **i3** - Tiling window manager
- **sway** - Wayland compositor (i3-compatible)
- All configs pre-configured and linked

### ✅ Modern Development Workflow
- **Neovim** with Lazy.nvim plugin manager
- **ZSH** with autosuggestions, syntax highlighting
- **Starship** prompt with git integration
- All modern CLI tools pre-installed

### ✅ Audio Just Works™
- PipeWire setup (replaces PulseAudio)
- Bluetooth audio support
- All audio controls configured
- Systemd user services enabled

### ✅ Portable & Reproducible
- Clone to USB stick
- Plug into any Debian/Ubuntu machine
- Run one command
- Perfect replica of your environment

---

## 📖 Usage Examples

### Fresh Debian Installation
```bash
# After installing Debian (minimal or standard)
git clone https://github.com/yourusername/dotfiles.git ~/dotfiles
cd ~/dotfiles
bash full_install.sh --full

# Log out and log back in
# Your entire desktop environment is ready!
```

### USB Stick Deployment
```bash
# On your main machine, clone to USB
git clone https://github.com/yourusername/dotfiles.git /media/usb/dotfiles

# On target machine
cd /media/usb/dotfiles
bash full_install.sh --unattended

# Walk away, come back to a fully configured system
```

### Selective Installation
```bash
# Just install development tools
bash full_install.sh
# Choose: 3, 5, 6 (packages, rust, nodejs)

# Just setup dwm
bash full_install.sh
# Choose: 7 (suckless tools)
```

---

## 🐛 Troubleshooting

### Check Installation Log
```bash
cat ~/dotfiles_install.log
```

### Re-run Individual Components
If a component fails, you can re-run just that script:
```bash
# Example: Re-run suckless installation
bash scripts/debian/install_suckless.sh
```

### Common Issues

**Fonts not displaying correctly:**
```bash
fc-cache -fv
```

**Audio not working:**
```bash
systemctl --user restart pipewire pipewire-pulse wireplumber
```

**dwm not in display manager:**
```bash
sudo cp /usr/share/xsessions/dwm.desktop /usr/share/xsessions/
```

**Cargo packages failing:**
```bash
# Install manually
source ~/.cargo/env
cargo install <package-name>
```

---

## 🔐 Security Notes

- SSH keys are generated with ed25519 (modern, secure)
- GitHub authentication uses official `gh` CLI
- All downloads use HTTPS
- Package managers verify signatures
- No passwords stored in dotfiles

---

## 🎯 Customization

### Add Your Own Packages
Edit the package lists in `opt/`:
```bash
# For Debian/Ubuntu
vim opt/debianPkgs

# For Rust tools
vim opt/cargoPkgs
```

### Customize dwm
Edit dwm configuration:
```bash
vim configs/suckless/dwm/config.h
# Then rebuild with:
bash scripts/debian/install_suckless.sh
```

### Add Your Own Scripts
Create new scripts in `scripts/debian/`:
```bash
vim scripts/debian/my_custom_setup.sh
chmod +x scripts/debian/my_custom_setup.sh
```

---

## 📊 System Requirements

### Minimum
- 2GB RAM
- 10GB free disk space
- Internet connection
- sudo privileges

### Recommended
- 4GB+ RAM
- 20GB+ free disk space
- Fast internet connection

---

## 🌟 Supported Operating Systems

| OS | Support | Package Manager | Notes |
|----|---------|-----------------|-------|
| Debian 12+ | ✅ Full | apt | Primary target |
| Ubuntu 22.04+ | ✅ Full | apt | Fully tested |
| Void Linux | ✅ Full | xbps | Original platform |
| Fedora | ⚠️ Partial | dnf | Basic support |
| MacOS | ⚠️ Partial | brew | Basic support |

---

## 📝 Post-Installation

### Start dwm
```bash
# From console
startx

# Or select "dwm" from your display manager
```

### Verify Installation
```bash
# Check installed tools
which bat eza ripgrep fd zoxide starship
rustc --version
node --version
docker --version

# Check audio
pactl list sinks

# Check services
systemctl --user status pipewire wireplumber
```

---

## 🤝 Contributing

Feel free to fork and customize for your own needs!

To update the package inventory:
```bash
# On your current system
xbps-query -l > ~/current-packages.txt
# Review and update opt/debianPkgs accordingly
```

---

## 📚 Additional Documentation

- [void-to-debian-packages.md](void-to-debian-packages.md) - Complete package inventory and migration guide
- [configs/nvim/README.md](configs/nvim/README.md) - Neovim configuration details
- [configs/suckless/dwm/README.md](configs/suckless/dwm/README.md) - dwm patches and customization

---

## 📜 License

MIT License - Use, modify, and distribute freely!

---

## ✨ Credits

**Author:** Eduardo Neville <eduadoneville82@gmail.com>

Built for terminal enthusiasts who value automation and reproducibility.

---

## 🎉 Enjoy Your New System!

Your development environment is now fully configured and ready to use. Happy coding! 💻✨

---

**Star ⭐ this repo if it helped you!**
