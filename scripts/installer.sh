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
