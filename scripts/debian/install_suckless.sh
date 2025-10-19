#!/usr/bin/env bash
# Author: Eduardo Neville <eduadoneville82@gmail.com>
# Description: Install suckless tools (dwm, slstatus, st, dmenu, slock)

set -e

DOTFILES_DIR="${HOME}/dotfiles"

_process() { echo "$(tput setaf 6)→ $1...$(tput sgr0)"; }
_success() { echo "$(tput setaf 2)✓ Success:$(tput sgr0) $1"; }
_error() { echo "$(tput setaf 1)✗ Error:$(tput sgr0) $1"; }

check_dependencies() {
    _process "Checking build dependencies"

    local deps=(
        "libx11-dev"
        "libxinerama-dev"
        "libxft-dev"
        "libxrandr-dev"
        "libimlib2-dev"
        "make"
        "gcc"
    )

    local missing=()
    for dep in "${deps[@]}"; do
        if ! dpkg -l | grep -q "^ii  $dep"; then
            missing+=("$dep")
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        _process "Installing missing dependencies: ${missing[*]}"
        sudo apt update
        sudo apt install -y "${missing[@]}"
    fi

    _success "All dependencies are installed"
}

install_dwm() {
    _process "Installing dwm"

    local dwm_dir="${DOTFILES_DIR}/configs/suckless/dwm"

    if [ ! -d "$dwm_dir" ]; then
        _error "dwm source directory not found at $dwm_dir"
        return 1
    fi

    cd "$dwm_dir"

    # Clean previous builds
    make clean 2>/dev/null || true

    # Build and install
    _process "Building dwm"
    if make; then
        _process "Installing dwm (requires sudo)"
        sudo make install
        _success "dwm installed successfully"
    else
        _error "Failed to build dwm"
        return 1
    fi

    cd - >/dev/null
}

install_slstatus() {
    _process "Installing slstatus"

    local slstatus_dir="${DOTFILES_DIR}/configs/suckless/slstatus"

    if [ ! -d "$slstatus_dir" ]; then
        _error "slstatus source directory not found at $slstatus_dir"
        return 1
    fi

    cd "$slstatus_dir"

    # Clean previous builds
    make clean 2>/dev/null || true

    # Build and install
    _process "Building slstatus"
    if make; then
        _process "Installing slstatus (requires sudo)"
        sudo make install
        _success "slstatus installed successfully"
    else
        _error "Failed to build slstatus"
        return 1
    fi

    cd - >/dev/null
}

install_st() {
    _process "Installing st (simple terminal)"

    local st_dir="${DOTFILES_DIR}/configs/suckless/st"

    if [ ! -d "$st_dir" ]; then
        _process "st source not found, cloning from suckless.org"
        mkdir -p "${DOTFILES_DIR}/configs/suckless"
        git clone https://git.suckless.org/st "$st_dir"
    fi

    cd "$st_dir"

    # Clean previous builds
    make clean 2>/dev/null || true

    # Build and install
    _process "Building st"
    if make; then
        _process "Installing st (requires sudo)"
        sudo make install
        _success "st installed successfully"
    else
        _error "Failed to build st"
        return 1
    fi

    cd - >/dev/null
}

install_dmenu() {
    _process "Installing dmenu"

    # dmenu is usually in repos, but we can build from source if preferred
    if [ -d "${DOTFILES_DIR}/configs/suckless/dmenu" ]; then
        local dmenu_dir="${DOTFILES_DIR}/configs/suckless/dmenu"
        cd "$dmenu_dir"
        make clean 2>/dev/null || true
        make && sudo make install
        cd - >/dev/null
        _success "dmenu installed from source"
    else
        _process "Installing dmenu from repository"
        sudo apt install -y dmenu
        _success "dmenu installed from repository"
    fi
}

install_slock() {
    _process "Installing slock (screen locker)"

    local slock_dir="${DOTFILES_DIR}/configs/slock"

    if [ -d "$slock_dir" ] && [ -f "$slock_dir/config.h" ]; then
        cd "$slock_dir"

        # Check if slock source exists
        if [ ! -f "slock.c" ]; then
            _process "Cloning slock source"
            git clone https://git.suckless.org/slock .
            # Copy our config
            [ -f config.def.h ] && cp config.h config.def.h
        fi

        make clean 2>/dev/null || true
        make && sudo make install
        cd - >/dev/null
        _success "slock installed from source"
    else
        _process "Installing slock from repository"
        sudo apt install -y slock
        _success "slock installed from repository"
    fi
}

setup_xinitrc() {
    _process "Setting up .xinitrc"

    local xinitrc="${DOTFILES_DIR}/configs/.xinitrc"

    if [ -f "$xinitrc" ]; then
        # Backup existing .xinitrc if present
        [ -f "${HOME}/.xinitrc" ] && mv "${HOME}/.xinitrc" "${HOME}/.xinitrc.backup"

        # Create symlink
        ln -sf "$xinitrc" "${HOME}/.xinitrc"
        _success ".xinitrc linked"
    else
        _error ".xinitrc not found in dotfiles"
    fi
}

create_dwm_desktop_entry() {
    _process "Creating dwm desktop entry for display managers"

    sudo mkdir -p /usr/share/xsessions

    sudo tee /usr/share/xsessions/dwm.desktop > /dev/null <<EOF
[Desktop Entry]
Name=dwm
Comment=Dynamic window manager
Exec=/usr/local/bin/dwm
Type=Application
Keywords=tiling;wm;windowmanager;window;manager;
EOF

    _success "dwm desktop entry created"
}

main() {
    _process "Installing suckless tools"

    check_dependencies

    # Install components
    install_dwm
    install_slstatus
    install_dmenu
    install_slock

    # Optional: install st (simple terminal)
    read -p "Install st (simple terminal)? (y/n): " install_st_choice
    if [[ "$install_st_choice" =~ ^[Yy]$ ]]; then
        install_st
    fi

    # Setup configuration files
    setup_xinitrc
    create_dwm_desktop_entry

    _success "Suckless tools installation complete"
    echo ""
    echo "To start dwm:"
    echo "  - From console: startx"
    echo "  - From display manager: Select 'dwm' at login"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
