# Void Linux Package Inventory
## For Migration to Debian

Total Packages: **1220**
Total Flatpaks: **2**

---

## FLATPAK APPLICATIONS

### Threema Work Beta (ch.threema.threema-work-desktop)
**What it does:** Secure messaging application focused on privacy
**Why you'd use it:** End-to-end encrypted communications for work/personal use, Swiss privacy standards
**Debian equivalent:** Keep as flatpak

### Zoom (us.zoom.Zoom)
**What it does:** Video conferencing platform
**Why you'd use it:** Virtual meetings, webinars, remote collaboration
**Debian equivalent:** Available as flatpak or deb package

---

## SYSTEM CORE & BASE SYSTEM

### base-system
**What it does:** Void Linux base system meta package
**Why you'd use it:** Essential system foundation
**Debian equivalent:** Not needed (Debian has its own base)

### base-files
**What it does:** Void Linux base system files
**Why you'd use it:** Core system file structure
**Debian equivalent:** Not needed (Debian has base-files)

### glibc / glibc-32bit / glibc-devel / glibc-locales
**What it does:** GNU C library - core system library
**Why you'd use it:** Essential for running programs on Linux
**Debian equivalent:** libc6 (installed by default)

### busybox
**What it does:** Swiss Army Knife of Embedded Linux - minimal utilities
**Why you'd use it:** Lightweight alternative to coreutils
**Debian equivalent:** busybox (optional, Debian uses full coreutils)

### coreutils
**What it does:** GNU core utilities (ls, cp, mv, etc.)
**Why you'd use it:** Essential file/text/shell utilities
**Debian equivalent:** coreutils (installed by default)

### bash
**What it does:** GNU Bourne Again Shell
**Why you'd use it:** Default shell for user interaction
**Debian equivalent:** bash (installed by default)

### dash
**What it does:** POSIX-compliant shell, smaller than bash
**Why you'd use it:** System scripts, faster than bash
**Debian equivalent:** dash (default /bin/sh on Debian)

### findutils
**What it does:** GNU Find Utilities (find, xargs, locate)
**Why you'd use it:** Searching for files and directories
**Debian equivalent:** findutils (installed by default)

### grep
**What it does:** GNU grep utility - text pattern matching
**Why you'd use it:** Searching text files for patterns
**Debian equivalent:** grep (installed by default)

### gzip / bzip2 / xz
**What it does:** Compression utilities
**Why you'd use it:** Compressing/decompressing files
**Debian equivalent:** gzip, bzip2, xz-utils

### sed / gawk
**What it does:** Stream editors and text processing
**Why you'd use it:** Text manipulation in scripts
**Debian equivalent:** sed, gawk

### diffutils
**What it does:** GNU diff utilities
**Why you'd use it:** Comparing files/directories
**Debian equivalent:** diffutils

---

## INIT SYSTEM & BOOT

### elogind
**What it does:** Standalone logind fork (session management)
**Why you'd use it:** User session/seat management without systemd
**Debian equivalent:** systemd (Debian uses systemd by default)

### acpid
**What it does:** ACPI daemon for power management events
**Why you'd use it:** Handle laptop lid close, power button, etc.
**Debian equivalent:** acpid

### eudev / eudev-libudev
**What it does:** Device manager (udev fork)
**Why you'd use it:** Dynamic device management
**Debian equivalent:** udev (part of systemd on Debian)

### grub / grub-i386-efi / grub-x86_64-efi
**What it does:** GRand Unified Bootloader 2
**Why you'd use it:** Boot multiple operating systems
**Debian equivalent:** grub-efi-amd64 or grub-pc

### dracut
**What it does:** Tool for generating initramfs/initrd images
**Why you'd use it:** Create initial ramdisk for booting
**Debian equivalent:** initramfs-tools (Debian default) or dracut

### efibootmgr
**What it does:** Tool to modify UEFI boot manager variables
**Why you'd use it:** Manage EFI boot entries
**Debian equivalent:** efibootmgr

---

## HARDWARE SUPPORT & DRIVERS

### linux-firmware
**What it does:** Binary firmware files for various hardware
**Why you'd use it:** Make hardware work (WiFi, GPU, etc.)
**Debian equivalent:** firmware-linux-free + firmware-linux-nonfree

### mesa / mesa-dri
**What it does:** Open source graphics drivers (OpenGL/Vulkan)
**Why you'd use it:** GPU acceleration for open source drivers
**Debian equivalent:** mesa-utils, libgl1-mesa-dri

### vulkan-loader / mesa-vulkan-*
**What it does:** Vulkan graphics API implementation
**Why you'd use it:** Modern graphics/gaming performance
**Debian equivalent:** libvulkan1, mesa-vulkan-drivers

### nvidia / nvidia-libs-32bit
**What it does:** NVIDIA proprietary graphics drivers
**Why you'd use it:** High performance NVIDIA GPU support
**Debian equivalent:** nvidia-driver (from non-free)

### xf86-video-* (amdgpu, intel, nouveau, etc.)
**What it does:** X.org video drivers
**Why you'd use it:** Display output for various GPUs
**Debian equivalent:** xserver-xorg-video-*

### xf86-input-* (evdev, libinput, synaptics, wacom)
**What it does:** X.org input drivers
**Why you'd use it:** Mouse, keyboard, touchpad, tablet support
**Debian equivalent:** xserver-xorg-input-*

### intel-media-driver / intel-video-accel
**What it does:** Intel GPU hardware video acceleration
**Why you'd use it:** Faster video decode/encode on Intel
**Debian equivalent:** intel-media-va-driver

### libva / libva-utils
**What it does:** Video Acceleration API
**Why you'd use it:** Hardware-accelerated video processing
**Debian equivalent:** libva2, vainfo

### alsa-lib / alsa-utils / alsa-pipewire
**What it does:** Advanced Linux Sound Architecture
**Why you'd use it:** Sound system interface
**Debian equivalent:** alsa-utils (installed by default)

### pipewire / libpipewire
**What it does:** Modern multimedia framework (audio/video)
**Why you'd use it:** Better audio handling than PulseAudio
**Debian equivalent:** pipewire, pipewire-audio

### wireplumber
**What it does:** Session manager for PipeWire
**Why you'd use it:** Manage PipeWire audio routing
**Debian equivalent:** wireplumber

### bluez / blueman
**What it does:** Bluetooth stack and GUI manager
**Why you'd use it:** Connect Bluetooth devices
**Debian equivalent:** bluez, blueman

### ipw2100-firmware / ipw2200-firmware
**What it does:** Firmware for Intel PRO/Wireless cards
**Why you'd use it:** Old Intel WiFi hardware support
**Debian equivalent:** firmware-ipw2x00

---

## PACKAGE MANAGEMENT & DEVELOPMENT

### base-devel
**What it does:** Void Linux development tools meta package
**Why you'd use it:** Compiling software from source
**Debian equivalent:** build-essential

### gcc
**What it does:** GNU Compiler Collection
**Why you'd use it:** Compile C/C++ programs
**Debian equivalent:** gcc

### make
**What it does:** GNU Make build automation
**Why you'd use it:** Build software from Makefiles
**Debian equivalent:** make

### autoconf / automake
**What it does:** GNU build system generators
**Why you'd use it:** Generate configure scripts
**Debian equivalent:** autoconf, automake

### pkg-config
**What it does:** Helper tool for compile/link flags
**Why you'd use it:** Find library information during compilation
**Debian equivalent:** pkg-config

### git
**What it does:** Distributed version control system
**Why you'd use it:** Track code changes, collaborate
**Debian equivalent:** git

### github-cli
**What it does:** GitHub CLI tool
**Why you'd use it:** Interact with GitHub from terminal
**Debian equivalent:** gh

### cmake
**What it does:** Cross-platform build system
**Why you'd use it:** Build modern C/C++ projects
**Debian equivalent:** cmake

### meson / ninja
**What it does:** Fast build system
**Why you'd use it:** Build projects faster than make
**Debian equivalent:** meson, ninja-build

### binutils
**What it does:** GNU binary utilities (ld, as, objdump, etc.)
**Why you'd use it:** Linker and assembler tools
**Debian equivalent:** binutils

### kernel-libc-headers
**What it does:** Linux API headers for userland development
**Why you'd use it:** Compile programs that use kernel interfaces
**Debian equivalent:** linux-libc-dev

---

## X WINDOW SYSTEM & DISPLAY

### xorg / xorg-minimal
**What it does:** X Window System implementation
**Why you'd use it:** Display server for GUI applications
**Debian equivalent:** xorg

### xorg-server
**What it does:** X.org display server
**Why you'd use it:** Core X11 display functionality
**Debian equivalent:** xserver-xorg

### xinit
**What it does:** X Window System initializer
**Why you'd use it:** Start X from console (startx command)
**Debian equivalent:** xinit

### xauth / iceauth
**What it does:** X authentication utilities
**Why you'd use it:** Manage X11 access control
**Debian equivalent:** xauth

### xrandr / xrdb / xset / xprop / xdpyinfo
**What it does:** X utilities for configuration and info
**Why you'd use it:** Configure displays, set X resources, query X
**Debian equivalent:** x11-xserver-utils

### xclip / xsel
**What it does:** Command-line clipboard utilities
**Why you'd use it:** Copy/paste from terminal to X clipboard
**Debian equivalent:** xclip, xsel

### xdotool
**What it does:** Simulate keyboard/mouse input in X
**Why you'd use it:** Automation, window manipulation
**Debian equivalent:** xdotool

### xbindkeys
**What it does:** Launch shell commands with keyboard/mouse
**Why you'd use it:** Custom keyboard shortcuts
**Debian equivalent:** xbindkeys

### xmodmap
**What it does:** Modify keymaps and pointer button mappings
**Why you'd use it:** Remap keys in X
**Debian equivalent:** x11-xserver-utils

### setxkbmap
**What it does:** Set keyboard layout in X
**Why you'd use it:** Change keyboard layouts
**Debian equivalent:** x11-xkbmap

---

## WINDOW MANAGERS & DESKTOP ENVIRONMENT

### dwm
**What it does:** Dynamic window manager for X
**Why you'd use it:** Lightweight, tiling window manager
**Debian equivalent:** dwm (or compile from suckless.org)

### i3 / i3-gaps / i3status
**What it does:** Tiling window manager
**Why you'd use it:** Keyboard-driven window management
**Debian equivalent:** i3-wm, i3status

### sway / swaybg / swayidle / swaylock
**What it does:** i3-compatible Wayland compositor
**Why you'd use it:** Wayland tiling window manager
**Debian equivalent:** sway, swaylock, swayidle

### waybar
**What it does:** Wayland status bar
**Why you'd use it:** Display system info in Sway/Wayland
**Debian equivalent:** waybar

### wlroots
**What it does:** Modular Wayland compositor library
**Why you'd use it:** Base for Sway and other Wayland compositors
**Debian equivalent:** libwlroots12 (or current version)

### Thunar
**What it does:** Xfce file manager
**Why you'd use it:** GUI file management
**Debian equivalent:** thunar

### exo
**What it does:** Extension library for Xfce
**Why you'd use it:** Support for Xfce applications
**Debian equivalent:** exo-utils

### rofi / dmenu
**What it does:** Application launchers
**Why you'd use it:** Launch apps via keyboard
**Debian equivalent:** rofi, dmenu

### dunst
**What it does:** Lightweight notification daemon
**Why you'd use it:** Display desktop notifications
**Debian equivalent:** dunst

### picom
**What it does:** Compositor for X11
**Why you'd use it:** Window transparency, shadows, effects
**Debian equivalent:** picom

### polybar
**What it does:** Status bar for window managers
**Why you'd use it:** Display system info (i3, dwm, etc.)
**Debian equivalent:** polybar

---

## TERMINAL & SHELL TOOLS

### alacritty / kitty / st / rxvt-unicode / xterm
**What it does:** Terminal emulators
**Why you'd use it:** Run shell commands in GUI
**Debian equivalent:** Same packages available

### tmux / screen
**What it does:** Terminal multiplexers
**Why you'd use it:** Multiple terminal sessions, detachable
**Debian equivalent:** tmux, screen

### zsh / zsh-* plugins
**What it does:** Z Shell - alternative to bash
**Why you'd use it:** Advanced shell with better features
**Debian equivalent:** zsh

### starship
**What it does:** Cross-shell prompt
**Why you'd use it:** Beautiful, fast shell prompt
**Debian equivalent:** Install via cargo or prebuilt binary

### fzf
**What it does:** Command-line fuzzy finder
**Why you'd use it:** Search files/history interactively
**Debian equivalent:** fzf

### ripgrep / fd
**What it does:** Fast search tools (grep/find alternatives)
**Why you'd use it:** Much faster searching
**Debian equivalent:** ripgrep, fd-find

### bat / exa / lsd
**What it does:** Modern cat/ls alternatives
**Why you'd use it:** Better syntax highlighting and display
**Debian equivalent:** bat, exa (or lsd)

### btop / htop
**What it does:** System resource monitors
**Why you'd use it:** Monitor CPU, RAM, processes
**Debian equivalent:** btop, htop

### ncdu
**What it does:** NCurses disk usage analyzer
**Why you'd use it:** Find what's using disk space
**Debian equivalent:** ncdu

### tree
**What it does:** Display directory tree structure
**Why you'd use it:** Visualize directory hierarchy
**Debian equivalent:** tree

### neovim / vim
**What it does:** Terminal text editors
**Why you'd use it:** Edit files in terminal
**Debian equivalent:** neovim, vim

---

## FILE MANAGERS & UTILITIES

### ranger / nnn
**What it does:** Terminal file managers
**Why you'd use it:** Navigate filesystem in terminal
**Debian equivalent:** ranger, nnn

### mc (midnight commander)
**What it does:** Two-panel file manager
**Why you'd use it:** Norton Commander-style file management
**Debian equivalent:** mc

### feh
**What it does:** Fast and light image viewer
**Why you'd use it:** View images, set wallpapers
**Debian equivalent:** feh

### mpv
**What it does:** Command-line video player
**Why you'd use it:** Play videos with minimal interface
**Debian equivalent:** mpv

### sxiv
**What it does:** Simple X Image Viewer
**Why you'd use it:** Lightweight image viewing
**Debian equivalent:** sxiv

---

## NETWORKING

### NetworkManager / NetworkManager-*
**What it does:** Network connection manager
**Why you'd use it:** Manage WiFi, Ethernet, VPN connections
**Debian equivalent:** network-manager

### iproute2
**What it does:** IP routing utilities (ip command)
**Why you'd use it:** Network configuration
**Debian equivalent:** iproute2

### iw / wireless_tools
**What it does:** Wireless configuration utilities
**Why you'd use it:** Configure WiFi from command line
**Debian equivalent:** iw, wireless-tools

### wpa_supplicant
**What it does:** WPA/WPA2 authentication
**Why you'd use it:** Connect to secured WiFi
**Debian equivalent:** wpasupplicant

### dhcpcd / dhclient
**What it does:** DHCP clients
**Why you'd use it:** Automatically get IP addresses
**Debian equivalent:** isc-dhcp-client (dhclient)

### dnsmasq
**What it does:** Lightweight DNS forwarder and DHCP server
**Why you'd use it:** Local DNS caching, network services
**Debian equivalent:** dnsmasq

### bind-utils
**What it does:** DNS utilities (dig, nslookup, host)
**Why you'd use it:** DNS troubleshooting
**Debian equivalent:** dnsutils

### curl / wget
**What it does:** Download files from the internet
**Why you'd use it:** Fetch files via HTTP/FTP
**Debian equivalent:** curl, wget

### openssh / openssh-server
**What it does:** Secure shell for remote access
**Why you'd use it:** Remote server administration
**Debian equivalent:** openssh-client, openssh-server

### openvpn / wireguard-tools
**What it does:** VPN software
**Why you'd use it:** Secure network tunnels
**Debian equivalent:** openvpn, wireguard

### nmap / nmap-gtk
**What it does:** Network scanner
**Why you'd use it:** Network discovery and security auditing
**Debian equivalent:** nmap, zenmap

### rsync
**What it does:** Fast incremental file transfer
**Why you'd use it:** Backup, sync files
**Debian equivalent:** rsync

### rclone
**What it does:** Sync files to/from cloud storage
**Why you'd use it:** Manage cloud storage from CLI
**Debian equivalent:** rclone

---

## WEB BROWSERS

### firefox
**What it does:** Mozilla Firefox web browser
**Why you'd use it:** Web browsing with privacy focus
**Debian equivalent:** firefox-esr or firefox from Mozilla

### chromium
**What it does:** Open source Chrome browser
**Why you'd use it:** Google-based web browsing
**Debian equivalent:** chromium

---

## COMMUNICATION & MESSAGING

### discord
**What it does:** Chat platform for communities
**Why you'd use it:** Gaming/community communication
**Debian equivalent:** Available as deb or flatpak

### signal-desktop
**What it does:** Secure messaging app
**Why you'd use it:** Private, encrypted messaging
**Debian equivalent:** signal-desktop

### telegram-desktop
**What it does:** Telegram messaging client
**Why you'd use it:** Fast cloud-based messaging
**Debian equivalent:** telegram-desktop

### thunderbird
**What it does:** Email client
**Why you'd use it:** Manage email accounts
**Debian equivalent:** thunderbird

### neomutt / mutt
**What it does:** Terminal email client
**Why you'd use it:** Read/send email from terminal
**Debian equivalent:** neomutt, mutt

---

## MULTIMEDIA & AUDIO/VIDEO

### ffmpeg6 / ffplay6
**What it does:** Multimedia framework (encode/decode/stream)
**Why you'd use it:** Convert videos, extract audio, stream
**Debian equivalent:** ffmpeg

### vlc
**What it does:** Versatile media player
**Why you'd use it:** Play almost any video/audio format
**Debian equivalent:** vlc

### mpv
**What it does:** Lightweight media player
**Why you'd use it:** Minimal, keyboard-driven video player
**Debian equivalent:** mpv

### pavucontrol
**What it does:** PulseAudio/PipeWire volume control
**Why you'd use it:** GUI audio device/stream management
**Debian equivalent:** pavucontrol

### helvum
**What it does:** GTK patchbay for PipeWire
**Why you'd use it:** Visual audio routing for PipeWire
**Debian equivalent:** helvum

### cmus
**What it does:** Console music player
**Why you'd use it:** Play music in terminal
**Debian equivalent:** cmus

### spotify / spotify-qt
**What it does:** Music streaming client
**Why you'd use it:** Listen to Spotify
**Debian equivalent:** Install via snap or flatpak

---

## IMAGE & GRAPHICS

### gimp
**What it does:** GNU Image Manipulation Program
**Why you'd use it:** Photo editing, graphic design
**Debian equivalent:** gimp

### inkscape
**What it does:** Vector graphics editor
**Why you'd use it:** Create/edit SVG graphics
**Debian equivalent:** inkscape

### krita
**What it does:** Digital painting application
**Why you'd use it:** Drawing, painting, illustrations
**Debian equivalent:** krita

### imagemagick
**What it does:** Image manipulation from CLI
**Why you'd use it:** Batch process images, convert formats
**Debian equivalent:** imagemagick

### flameshot / scrot / maim
**What it does:** Screenshot tools
**Why you'd use it:** Capture screen/windows
**Debian equivalent:** flameshot, scrot, maim

### kcolorchooser
**What it does:** KDE's color chooser
**Why you'd use it:** Pick colors from screen
**Debian equivalent:** kcolorchooser

---

## DOCUMENT VIEWERS & OFFICE

### zathura / zathura-*
**What it does:** Minimalist document viewer
**Why you'd use it:** Read PDFs with vim-like keybindings
**Debian equivalent:** zathura

### mupdf
**What it does:** Lightweight PDF viewer
**Why you'd use it:** Fast PDF viewing
**Debian equivalent:** mupdf

### libreoffice
**What it does:** Office suite (Writer, Calc, Impress)
**Why you'd use it:** Create documents, spreadsheets, presentations
**Debian equivalent:** libreoffice

### texlive
**What it does:** TeX/LaTeX distribution
**Why you'd use it:** Create professional documents, papers
**Debian equivalent:** texlive

---

## FILE SYSTEMS & STORAGE

### btrfs-progs
**What it does:** Btrfs filesystem utilities
**Why you'd use it:** Manage Btrfs filesystems (snapshots, etc.)
**Debian equivalent:** btrfs-progs

### e2fsprogs
**What it does:** ext2/3/4 filesystem utilities
**Why you'd use it:** Manage ext filesystems
**Debian equivalent:** e2fsprogs

### xfsprogs
**What it does:** XFS filesystem utilities
**Why you'd use it:** Manage XFS filesystems
**Debian equivalent:** xfsprogs

### dosfstools
**What it does:** DOS filesystem tools (FAT32)
**Why you'd use it:** Format/check FAT filesystems
**Debian equivalent:** dosfstools

### ntfs-3g
**What it does:** NTFS filesystem driver
**Why you'd use it:** Read/write Windows NTFS drives
**Debian equivalent:** ntfs-3g

### exfat-utils
**What it does:** exFAT filesystem utilities
**Why you'd use it:** Work with exFAT (USB drives, SD cards)
**Debian equivalent:** exfat-fuse, exfat-utils

### f2fs-tools
**What it does:** Flash-Friendly File System tools
**Why you'd use it:** Optimized for flash storage
**Debian equivalent:** f2fs-tools

### fuse / fuse3
**What it does:** Filesystem in Userspace
**Why you'd use it:** Mount custom filesystems
**Debian equivalent:** fuse3

### lvm2
**What it does:** Logical Volume Manager
**Why you'd use it:** Flexible disk partitioning
**Debian equivalent:** lvm2

### cryptsetup
**What it does:** Setup encrypted volumes (LUKS)
**Why you'd use it:** Disk encryption
**Debian equivalent:** cryptsetup

### gparted
**What it does:** GNOME Partition Editor
**Why you'd use it:** GUI partition management
**Debian equivalent:** gparted

### parted
**What it does:** GNU partition editor
**Why you'd use it:** Command-line partition management
**Debian equivalent:** parted

---

## ARCHIVING & COMPRESSION

### 7zip / p7zip
**What it does:** File archiver with high compression
**Why you'd use it:** Create/extract .7z archives
**Debian equivalent:** p7zip-full

### zip / unzip
**What it does:** ZIP archive utilities
**Why you'd use it:** Create/extract .zip files
**Debian equivalent:** zip, unzip

### tar
**What it does:** Tape archive utility
**Why you'd use it:** Create/extract tar archives
**Debian equivalent:** tar

### rar / unrar
**What it does:** RAR archive utilities
**Why you'd use it:** Extract .rar files
**Debian equivalent:** unrar (non-free)

### cabextract
**What it does:** Extract Microsoft Cabinet files
**Why you'd use it:** Extract .cab files
**Debian equivalent:** cabextract

---

## SYSTEM UTILITIES

### fastfetch / neofetch
**What it does:** System information fetching tools
**Why you'd use it:** Display system info with ASCII art
**Debian equivalent:** fastfetch, neofetch

### lshw / hwinfo
**What it does:** Hardware information tools
**Why you'd use it:** List detailed hardware info
**Debian equivalent:** lshw, hwinfo

### smartmontools
**What it does:** Monitor disk health (SMART)
**Why you'd use it:** Check drive health, predict failures
**Debian equivalent:** smartmontools

### lm_sensors
**What it does:** Hardware monitoring (temps, fans)
**Why you'd use it:** Monitor system temperatures
**Debian equivalent:** lm-sensors

### tlp / powertop
**What it does:** Power management for laptops
**Why you'd use it:** Extend battery life
**Debian equivalent:** tlp, powertop

### brightnessctl / light
**What it does:** Control screen brightness
**Why you'd use it:** Adjust brightness from CLI/scripts
**Debian equivalent:** brightnessctl

### redshift / gammastep
**What it does:** Adjust screen color temperature
**Why you'd use it:** Reduce blue light at night
**Debian equivalent:** redshift

### stow
**What it does:** Symlink farm manager
**Why you'd use it:** Manage dotfiles with symlinks
**Debian equivalent:** stow

---

## CLIPBOARD & SCREEN MANAGEMENT

### clipmenu / clipnotify
**What it does:** Clipboard manager using dmenu
**Why you'd use it:** Access clipboard history
**Debian equivalent:** Same or install from source

### xclip / xsel
**What it does:** CLI clipboard utilities
**Why you'd use it:** Copy/paste from command line
**Debian equivalent:** xclip, xsel

### redshift
**What it does:** Adjust color temperature of screen
**Why you'd use it:** Reduce eye strain at night
**Debian equivalent:** redshift

---

## CONTAINERIZATION & VIRTUALIZATION

### docker / docker-cli / docker-compose
**What it does:** Container platform
**Why you'd use it:** Run applications in containers
**Debian equivalent:** docker.io, docker-compose

### containerd
**What it does:** Container runtime
**Why you'd use it:** Backend for Docker
**Debian equivalent:** containerd

### qemu / qemu-*
**What it does:** Machine emulator and virtualizer
**Why you'd use it:** Run virtual machines
**Debian equivalent:** qemu-system

### libvirt / virt-manager
**What it does:** Virtualization API and manager
**Why you'd use it:** Manage VMs with GUI
**Debian equivalent:** libvirt-daemon, virt-manager

### gnome-boxes
**What it does:** Simple GNOME virtualization
**Why you'd use it:** Easy VM creation/management
**Debian equivalent:** gnome-boxes

---

## PRINTING

### cups / cups-filters
**What it does:** Common UNIX Printing System
**Why you'd use it:** Print to printers
**Debian equivalent:** cups

### system-config-printer
**What it does:** Printer configuration tool
**Why you'd use it:** Add/manage printers with GUI
**Debian equivalent:** system-config-printer

---

## SECURITY & ENCRYPTION

### gnupg
**What it does:** GNU Privacy Guard (GPG)
**Why you'd use it:** Encrypt/sign files and emails
**Debian equivalent:** gnupg

### pass
**What it does:** Standard unix password manager
**Why you'd use it:** Manage passwords using GPG
**Debian equivalent:** pass

### keepassxc
**What it does:** Cross-platform password manager
**Why you'd use it:** Store passwords securely
**Debian equivalent:** keepassxc

### yubikey-manager
**What it does:** Manage YubiKey devices
**Why you'd use it:** Configure hardware security keys
**Debian equivalent:** yubikey-manager

---

## CRYPTOCURRENCY

### electrum
**What it does:** Lightweight Bitcoin wallet
**Why you'd use it:** Manage Bitcoin without full node
**Debian equivalent:** electrum

---

## FONTS (Extensive Collection)

Your system has a comprehensive font collection including:
- **DejaVu fonts** - Default Unicode fonts
- **Liberation fonts** - Metric-compatible with Arial, Times, Courier
- **GNU FreeFont** - High-quality free outline fonts
- **Adobe Source fonts** - Source Code Pro, Sans Pro, Serif Pro
- **Google Roboto** - Modern Android/Google fonts
- **Noto fonts** - Google's comprehensive Unicode fonts
- **Font Awesome** - Icon fonts
- **Various script-specific fonts** - Arabic (Amiri, KACST, Scheherazade), Hebrew (Culmus, Alef), Asian languages, etc.

**Why you'd use them:** Display text in various languages and scripts correctly
**Debian equivalent:** fonts-dejavu, fonts-liberation, fonts-noto, fonts-roboto, etc.

---

## LANGUAGE & SPELL CHECKING

### hunspell / hunspell-*
**What it does:** Spell checker with dictionaries
**Why you'd use it:** Spell checking in multiple languages (EN, DE, ES, FR, IT, PL, PT)
**Debian equivalent:** hunspell, hunspell-* dictionaries

### aspell / aspell-*
**What it does:** Alternative spell checker
**Why you'd use it:** Spell checking for terminal apps
**Debian equivalent:** aspell, aspell-* dictionaries

---

## DEVELOPMENT LIBRARIES (Selected Important Ones)

### GTK+3 / GTK4
**What it does:** GIMP Toolkit - GUI framework
**Why you'd use it:** Required for GTK applications
**Debian equivalent:** libgtk-3-0, libgtk-4-1

### Qt5 / Qt6
**What it does:** Cross-platform GUI framework
**Why you'd use it:** Required for Qt applications
**Debian equivalent:** libqt5*, libqt6*

### SDL2 / SDL3
**What it does:** Simple DirectMedia Layer - game development
**Why you'd use it:** Required for SDL games/applications
**Debian equivalent:** libsdl2-2.0-0

### Python3 / python3-*
**What it does:** Python programming language
**Why you'd use it:** Run Python scripts and applications
**Debian equivalent:** python3, python3-*

### Nodejs / npm
**What it does:** JavaScript runtime and package manager
**Why you'd use it:** Run JS apps, web development
**Debian equivalent:** nodejs, npm

### Rust / cargo
**What it does:** Rust programming language
**Why you'd use it:** Build Rust applications
**Debian equivalent:** rustc, cargo

### Go
**What it does:** Go programming language
**Why you'd use it:** Build Go applications
**Debian equivalent:** golang

### OpenSSL / LibreSSL
**What it does:** SSL/TLS cryptography library
**Why you'd use it:** Secure connections, required by many apps
**Debian equivalent:** libssl3

---

## TIME SYNCHRONIZATION

### chrony
**What it does:** NTP client/server
**Why you'd use it:** Keep system time accurate
**Debian equivalent:** chrony or systemd-timesyncd

### ntp
**What it does:** Network Time Protocol daemon
**Why you'd use it:** Alternative to chrony for time sync
**Debian equivalent:** ntp

---

## SYSTEM MONITORING & LOGGING

### syslog-ng / rsyslog
**What it does:** System logging daemon
**Why you'd use it:** Collect and manage system logs
**Debian equivalent:** rsyslog (default on Debian)

---

## ADDITIONAL NOTABLE PACKAGES

### wine / wine-32bit
**What it does:** Run Windows applications on Linux
**Why you'd use it:** Use Windows software
**Debian equivalent:** wine, wine32

### java-openjdk / java-jre
**What it does:** Java runtime environment
**Why you'd use it:** Run Java applications
**Debian equivalent:** default-jre, openjdk-*-jre

### libreoffice
**What it does:** Office productivity suite
**Why you'd use it:** Documents, spreadsheets, presentations
**Debian equivalent:** libreoffice

---

## NOTES FOR DEBIAN MIGRATION

### Packages You DON'T Need on Debian:
- base-system, base-files (Debian has its own)
- elogind (Debian uses systemd)
- eudev (Debian uses systemd's udev)
- xbps, xtools (Void-specific package management)
- Void-specific service management tools

### Critical Differences:
1. **Init System:** Void uses runit, Debian uses systemd
2. **Package Manager:** Void uses xbps, Debian uses apt/dpkg
3. **Service Management:** Void uses sv/runit, Debian uses systemctl
4. **32-bit Support:** Void uses `-32bit` suffix, Debian uses `:i386` architecture

### Package Name Differences (Common):
- Void: `mesa-dri` → Debian: `libgl1-mesa-dri`
- Void: `eudev-libudev` → Debian: `libudev1` (from systemd)
- Void: `qt5-*` → Debian: `libqt5*` or `qt5-*`
- Void: `python3-*` → Debian: `python3-*` (usually same)

### Recommended Debian Package Groups:
- `build-essential` (replaces base-devel)
- `linux-headers-$(uname -r)` (for DKMS/driver compilation)
- `firmware-linux-nonfree` (for hardware support)
- `nvidia-driver` (if using NVIDIA)

### Your Core Workflow Packages to Install First on Debian:
1. **Window Manager:** i3 or sway
2. **Terminal:** alacritty or kitty
3. **Shell:** zsh with your dotfiles
4. **Editor:** neovim
5. **Browser:** firefox-esr or chromium
6. **File Manager:** thunar or ranger
7. **Utilities:** fzf, ripgrep, fd-find, bat
8. **Monitoring:** btop, htop
9. **Audio:** pipewire, wireplumber, pavucontrol
10. **Networking:** network-manager
11. **Git:** git, github-cli
12. **Development:** build-essential, cmake, python3, nodejs

---

## LANGUAGE-SPECIFIC PACKAGE MANAGERS

### CARGO / RUST PACKAGES (18 packages)

These are Rust applications installed via `cargo install`:

#### agg (v1.5.0)
**What it does:** asciinema gif generator
**Why you'd use it:** Convert asciinema recordings to animated GIFs
**Migration:** cargo install agg

#### asciinema (v3.0.0-rc.4)
**What it does:** Terminal session recorder
**Why you'd use it:** Record and share terminal sessions
**Migration:** cargo install asciinema

#### avm (v0.31.1)
**What it does:** Anchor Version Manager for Solana development
**Why you'd use it:** Manage Anchor framework versions for Solana smart contracts
**Migration:** cargo install --git https://github.com/coral-xyz/anchor avm

#### bat (v0.25.0)
**What it does:** Cat clone with syntax highlighting and git integration
**Why you'd use it:** View files with beautiful syntax highlighting
**Migration:** cargo install bat (or apt install bat on Debian)

#### cargo-binstall (v1.12.7)
**What it does:** Binary installation for cargo
**Why you'd use it:** Install cargo packages from binaries instead of compiling
**Migration:** cargo install cargo-binstall

#### csvlens (v0.13.0)
**What it does:** CSV file viewer in terminal
**Why you'd use it:** Browse and analyze CSV files like less
**Migration:** cargo install csvlens

#### du-dust (v1.2.1)
**What it does:** More intuitive version of du (disk usage)
**Why you'd use it:** Visualize disk usage with a tree view
**Migration:** cargo install du-dust

#### dysk (v2.10.1)
**What it does:** Get information about your mounted filesystems
**Why you'd use it:** Alternative to df with better output
**Migration:** cargo install dysk

#### eza (v0.21.3)
**What it does:** Modern replacement for ls (formerly exa)
**Why you'd use it:** Better file listing with colors, icons, git status
**Migration:** cargo install eza

#### fd-find (v10.2.0)
**What it does:** Simple, fast alternative to find
**Why you'd use it:** Much faster and easier to use than find
**Migration:** cargo install fd-find (or apt install fd-find on Debian)

#### git-delta (v0.18.2)
**What it does:** Syntax-highlighting pager for git
**Why you'd use it:** Beautiful git diffs with syntax highlighting
**Migration:** cargo install git-delta (or apt install git-delta on Debian)

#### gitui (v0.27.0)
**What it does:** Terminal UI for git
**Why you'd use it:** Fast keyboard-driven git interface
**Migration:** cargo install gitui

#### jless (v0.9.0)
**What it does:** JSON viewer for terminal
**Why you'd use it:** Browse and search JSON files interactively
**Migration:** cargo install jless

#### ripgrep (v14.1.1)
**What it does:** Ultra-fast grep alternative
**Why you'd use it:** Search code/text much faster than grep
**Migration:** cargo install ripgrep (or apt install ripgrep on Debian)

#### starship (v1.23.0)
**What it does:** Minimal, fast, customizable shell prompt
**Why you'd use it:** Beautiful cross-shell prompt with git/lang info
**Migration:** cargo install starship (or use prebuilt binary)

#### t-rec (v0.7.9)
**What it does:** Terminal recorder that generates animated GIFs
**Why you'd use it:** Record terminal sessions as GIFs
**Migration:** cargo install t-rec

#### television (v0.11.9)
**What it does:** Fuzzy finder with preview
**Why you'd use it:** Advanced file/text searching with preview
**Migration:** cargo install television

#### zoxide (v0.9.8)
**What it does:** Smarter cd command that learns your habits
**Why you'd use it:** Jump to frequently used directories quickly
**Migration:** cargo install zoxide (or apt install zoxide on Debian)

---

### NPM / NODE.JS PACKAGES (3 packages)

These are globally installed npm packages:

#### @anthropic-ai/claude-code (v2.0.22)
**What it does:** Claude Code CLI tool
**Why you'd use it:** Interact with Claude AI from terminal
**Migration:** npm install -g @anthropic-ai/claude-code

#### corepack (v0.34.0)
**What it does:** Package manager manager for Node.js
**Why you'd use it:** Manage yarn/pnpm versions
**Migration:** Comes with Node.js (included)

#### npm (v11.6.0)
**What it does:** Node Package Manager
**Why you'd use it:** Install JavaScript packages
**Migration:** Comes with Node.js (installed by default)

**Note:** You're using nvm (Node Version Manager) at version v24.9.0. To migrate:
1. Install nvm on Debian: `curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash`
2. Install your Node version: `nvm install 24.9.0`
3. Reinstall global packages: `npm install -g @anthropic-ai/claude-code`

---

### PYTHON / PIP PACKAGES

No user-installed pip packages detected. All Python packages are managed through the system package manager.

---

### OTHER PACKAGE MANAGERS

- **Ruby Gems:** Not in use
- **Lua Rocks:** Not in use
- **Perl CPAN:** Not in use
- **Go modules:** Managed per-project (not global)

---

## SUMMARY

You have a well-configured development and desktop system with:
- **Window Managers:** dwm, i3/i3-gaps, sway (Wayland)
- **Terminal-centric workflow:** Advanced CLI tools (many via cargo)
- **Multimedia:** Full audio/video stack with PipeWire
- **Development:** Complete toolchain for C/C++, Python, Rust, Go, JS
- **Containerization:** Docker setup
- **Graphics:** NVIDIA support + open source drivers
- **Privacy/Security:** VPN, encryption, secure messaging
- **Modern CLI Tools:** Extensive Rust-based utilities (18 cargo packages)

The majority of these packages have direct Debian equivalents. Your biggest adaptation will be to systemd (from runit) and apt (from xbps). Your dotfiles and configurations should mostly transfer directly.

### Migration Priority:

**Critical First Installs:**
1. Install cargo/rust toolchain first
2. Install nvm and Node.js
3. Reinstall cargo packages (many available in Debian repos: bat, ripgrep, fd-find, git-delta, zoxide)
4. Reinstall npm global packages
5. Configure your shell (zsh) and install starship
6. Install window manager and terminal emulator
7. Set up PipeWire for audio

**Your system is heavily optimized for terminal/development work with modern Rust CLI tools.**
