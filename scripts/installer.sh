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
	
	cd configs
	mkdir HyprSource
	cd HyprSource

	## We get Source
	wget https://github.com/hyprwm/Hyprland/releases/download/v0.24.1/source-v0.24.1.tar.gz
	tar -xvf source-v0.24.1.tar.gz

	wget https://gitlab.freedesktop.org/wayland/wayland-protocols/-/releases/1.31/downloads/wayland-protocols-1.31.tar.xz
	tar -xvJf wayland-protocols-1.31.tar.xz

	wget https://gitlab.freedesktop.org/wayland/wayland/-/releases/1.22.0/downloads/wayland-1.22.0.tar.xz
	tar -xvJf wayland-1.22.0.tar.xz

	wget https://gitlab.freedesktop.org/emersion/libdisplay-info/-/releases/0.1.1/downloads/libdisplay-info-0.1.1.tar.xz
	tar -xvJf libdisplay-info-0.1.1.tar.xz

	cd wayland-1.22.0
	mkdir build &&
	cd    build &&

	meson setup ..            \
	      --prefix=/usr       \
	      --buildtype=release \
	      -Ddocumentation=false &&
	ninja
	sudo ninja install

	cd ../..
	cd wayland-protocols-1.31

	mkdir build &&
	cd    build &&

	meson setup --prefix=/usr --buildtype=release &&
	ninja

	sudo ninja install

	cd ../..
	cd libdisplay-info-0.1.1/

	mkdir build &&
	cd    build &&

	meson setup --prefix=/usr --buildtype=release &&
	ninja

	sudo ninja install

	cd ../..
	chmod a+rw hyprland-source

	cd hyprland-source/
	sed -i 's/\/usr\/local/\/usr/g' config.mk
	cd ../
	git clone https://gitlab.freedesktop.org/emersion/libliftoff.git
	cd libliftoff
	meson setup build/
	ninja -C build/
	cd build
	sudo ninja install 
	cd ../../
	sudo apt install libsystemd-dev
	cd hyprland-source
	sudo make install
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
