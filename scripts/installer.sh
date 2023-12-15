# ----------------------------------------------------------------------------------------

#
# Nix installer
#
_installNix(){

    echo "Installing the nix package manager"

    curl -L https://nixos.org/nix/install | sh -s -- --daemon
 
    echo "Installing nix home-manager"
    nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
    nix-channel --update

    nix-shell '<home-manager>' -A install

    home-manager switch
}

#
# Hyperland installer for Debian
#
_installHyperland(){
	sudo apt-get install -y meson wget build-essential ninja-build cmake-extras cmake gettext gettext-base fontconfig libfontconfig-dev libffi-dev libxml2-dev libdrm-dev libxkbcommon-x11-dev libxkbregistry-dev libxkbcommon-dev libpixman-1-dev libudev-dev libseat-dev seatd libxcb-dri3-dev libegl-dev libgles2 libegl1-mesa-dev glslang-tools libinput-bin libinput-dev libxcb-composite0-dev libavutil-dev libavcodec-dev libavformat-dev libxcb-ewmh2 libxcb-ewmh-dev libxcb-present-dev libxcb-icccm4-dev libxcb-render-util0-dev libxcb-res0-dev libxcb-xinput-dev xdg-desktop-portal-wlr libtomlplusplus3 hwdata
	sudo apt install libpango1.0-dev -y
	sudo apt install libgbm-dev -y
	

}

# ----------------------------------------------------------------------------------------

#
# Creates a symlink between the source and target locations.
#
_installSymLink() {
    symlinkName=$1   # This is just the name for logging purposes
    linkSource=$2
    linkTarget=$3
    
    # Remove existing symlink, directory, or file at the target location
    [ -L "${linkTarget}" ] && rm "${linkTarget}"
    [ -d "${linkTarget}" ] && rm -rf "${linkTarget}"
    [ -f "${linkTarget}" ] && rm "${linkTarget}"
    
    # Create the new symlink
    # f -> -f-orce link between files
    # s -> makes the -s-ymbolic link
    ln -fs $linkSource $linkTarget
    echo "Symlink ${linkSource} -> ${linkTarget} created (Named: ${symlinkName})."
}

# -----------------------------------------------------------------------------------------
