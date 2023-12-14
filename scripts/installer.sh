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
