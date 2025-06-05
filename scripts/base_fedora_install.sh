#!/usr/bin/env bash
# Author: Eduardo Neville <eduadoneville82@gmail.com>
# Description: Install tools for Fedora Server with dwm setup
source $(dirname "$0")/scripts/base_fedora_install.sh

DOTFILES_DIR="${HOME}/dotfiles"
PACKAGE_MANAGER="dnf"
LOG="${HOME}/Library/Logs/dotfiles.log"

# Confirm Fedora OS
OS=$(hostnamectl | grep "Operating System" | awk -F": " '{print $2}' | awk '{print $1}')
if [[ "$OS" != "Fedora" ]]; then
    echo "This script is tailored for Fedora Server. Exiting."
    exit 1
fi

_process() { echo "$(tput setaf 6)→ $1...$(tput sgr0)"; }
_success() { echo "$(tput setaf 2)✓ Success:$(tput sgr0) $1"; }
_error() { echo "$(tput setaf 1)✗ Error:$(tput sgr0) $1"; }

# Check if a program exists
program_exists() { command -v "$1" >/dev/null 2>&1; }

# Install base dependencies
install_base() {
    _process "Installing base X11 and development tools"
    sudo dnf groupinstall -y "X Window System"
    sudo dnf install -y @development-tools git
    _success "Base dependencies installed"
}

# Install packages from Fedora repositories
install_packages() {
    _process "Installing packages from Fedora repositories"
    sudo dnf install -y flameshot slim bluez pipewire dunst upower NetworkManager rofi feh picom brightnessctl slock
    _success "Packages installed"
}

# Install dwm from source
install_dwm() {
    _process "Installing dwm from source"
    git clone https://git.suckless.org/dwm ~/dwm
    cd ~/dwm
    [ -f "${DOTFILES_DIR}/configs/suckless/dwm-6.2/config.h" ] && cp "${DOTFILES_DIR}/configs/suckless/dwm-6.2/config.h" .
    make
    sudo make install
    cd -
    _success "dwm installed"
}

# Install slstatus from source
install_slstatus() {
    _process "Installing slstatus from source"
    git clone https://git.suckless.org/slstatus ~/slstatus
    cd ~/slstatus
    make
    sudo make install
    cd -
    _success "slstatus installed"
}

# Configure dunst
configure_dunst() {
    _process "Configuring dunst"
    mkdir -p ~/.config/dunst
    cp /etc/dunst/dunstrc ~/.config/dunst/dunstrc
    echo '[global]\n    geometry = "300x5-10+10"' >> ~/.config/dunst/dunstrc
    _success "dunst configured"
}

# Configure slstatus
configure_slstatus() {
    _process "Configuring slstatus"
    cd ~/slstatus
    cat > config.h << EOL
static const struct arg args[] = {
    { cpu_perc, "CPU: %s%% ", NULL },
    { ram_perc, "RAM: %s%% ", NULL },
    { datetime, "%s", "%Y-%m-%d %H:%M:%S" },
};
EOL
    make clean
    make
    sudo make install
    cd -
    _success "slstatus configured"
}

# Configure slock (minimal, using default package)
configure_slock() {
    _process "Configuring slock"
    _success "slock installed with default settings (customize via source if needed)"
}

# Configure slim
configure_slim() {
    _process "Configuring slim"
    sudo sed -i 's/^default_session.*/default_session dwm/' /etc/slim.conf
    sudo sed -i 's/^current_theme.*/current_theme default/' /etc/slim.conf
    _success "slim configured"
}

# Configure rofi
configure_rofi() {
    _process "Configuring rofi"
    mkdir -p ~/.config/rofi
    # Assuming current.rasi is in ~/dotfiles/configs/rofi/current.rasi
    [ -f "${DOTFILES_DIR}/configs/rofi/current.rasi" ] && cp "${DOTFILES_DIR}/configs/rofi/current.rasi" ~/.config/rofi/current.rasi
    _success "rofi configured"
}

# Configure .xinitrc
configure_xinitrc() {
    _process "Configuring .xinitrc"
    cat > ~/.xinitrc << EOL
#!/bin/sh
feh --bg-scale /path/to/wallpaper.jpg &
picom &
dunst &
slstatus &
exec dwm
EOL
    chmod +x ~/.xinitrc
    _success ".xinitrc configured"
}

# Enable services
enable_services() {
    _process "Enabling system services"
    sudo systemctl enable NetworkManager
    sudo systemctl enable bluetooth
    sudo systemctl enable slim
    systemctl --user enable pipewire
    _success "Services enabled"
}

# Main installation process
install() {
    install_base
    install_packages
    install_dwm
    install_slstatus
    configure_dunst
    configure_slstatus
    configure_slock
    configure_slim
    configure_rofi
    configure_xinitrc
    enable_services
    _success "Installation and configuration complete. Reboot to test."
}

install
