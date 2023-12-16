#!/usr/bin/env bash
# Author: Eduardo Nevile <eduardo.nevillecastro@epfl.ch>
# Description:
# Automatically install tools for different OS
source $(dirname "$0")/scripts/installer.sh

# TODO
# Link dotfiles [ ]
# Zsh exec [ ]
# Packer and NVIM setup [ ]
# Brew install of packages [X]

# ---------
# Detect the operating system
# ---------
if [[ "$(uname)" == "Linux" ]]; then
    DOTFILES_DIR="${HOME}/dotfiles"  # Linux root directory
    PACKAGE_MANAGER="apt"
else
    DOTFILES_DIR="${HOME}/dotfiles"  # macOS
    PACKAGE_MANAGER="brew"
fi

LOG="${HOME}/Library/Logs/dotfiles.log"
GITHUB_USER=EduardoNeville
GITHUB_REPO=dotfiles

_process() {
    printf "$(tput setaf 6) %s...$(tput sgr0)\n" "$@"
}

_success() {
    local message=$1
    printf "%s✓ Success:%s\n" "$(tput setaf 2)" "$(tput sgr0) $message"
}

# Check if program exists 
function program_exists() {
    local ret='0'
    command -v $1 >/dev/null 2>&1 || { local ret='1'; }

    # fail on non-zero return value.
    if [ "$ret" -ne 0 ]; then
        return 1
    fi

    return 0
}

# ---
# Linking files
# --
link_dotfiles() {
	# symlink files to the HOME directory.
    _process "→ Symlinking dotfiles in /configs into .config"

    DOT_CONF_DIR=${DOTFILES_DIR}/configs
    CONFIG_DIR=${HOME}/.config

    # Loop through all files and directories in `~/dotfiles/configs`
    for item in "${DOT_CONF_DIR}"/*; do
          # Get the base name of the item
          basename=$(basename "${item}")
          
          # Create a symlink in `~/.config`, skip if it already exists
          target="${CONFIG_DIR}/${basename}"
          if [ ! -e "${target}" ]; then
            ln -s "${item}" "${target}"
            echo "Created symlink for ${basename}"
          else
            echo "Symlink for ${basename} already exists, skipped."
          fi
    done

    echo "Symlink for zshrc"
    ln -s ~/dotfiles/configs/zsh-conf/.zshrc ~/.zshrc

    __success "All files have been symlinked"
}
# ---
# Installing Homebrew 
# ---
install_homebrew() {
    _process "→ Installing Homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"

    _process "→ Running brew doctor"
    brew doctor
    [[ $? ]] \
    && _success "Installed Homebrew"
}

# ---
#Backup packages 
# ---
function brew_backup_new_packages(){
	_process "-> Backing up new packages into $PACKAGE_MANAGER"
    if ! type -P 'brew' &> /dev/null; then
        _error "Homebrew not found while backing up NEW PACKAGES"
    else
        _process "→ Backing up new packages in $DOTFILES_DIR/opt/Brewfile"
        brew bundle dump --file="opt/Brewfile" -fv
    fi
}

# ---
#Installing packages
# ---
function brew_installing_packages(){
	_process "-> Installing up new packages into brew"
    if ! type -P 'brew' &> /dev/null; then
        _error "Homebrew not found while installing up NEW PACKAGES"
    else
        _process "→ Installing up new packages in $DOTFILES_DIR/opt/Brewfile"
        brew bundle --file="$DOTFILES_DIR/opt/Brewfile" -v 
    fi
}

apt_install_pkgs(){
	# symlink files to the HOME directory.
	if [[ -f "$DOTFILES_DIR/opt/aptInstall" ]]; then
		_process "→ Installing apt packages"

		# Set variable for list of files
		files="$DOTFILES_DIR/opt/aptInstall"

		# Store IFS separator within a temp variable
		OIFS=$IFS
		# Set the separator to a carriage return & a new line break
		# read in passed-in file and store as an array
		IFS=$'\r\n'
		links=($(cat "${files}"))

		# Loop through array of files
		for index in ${!links[*]}
		do
			_process "→ Installing apt package ${links[$index]}"
			# set IFS back to space to split string on
			IFS=$' '
			sudo apt install ${links[$index]}
			# set separater back to carriage return & new line break
			IFS=$'\r\n'
		done
		# Reset IFS back
		IFS=$OIFS
		[[ $? ]] && _success "All files have been copied"
	fi
}

# ---
#Installing zsh plugins
# ---
function zsh_plugins(){
	_process "-> Installing ZSH Plugins"

    zsh_loc="${DOTFILES_DIR}/configs/.config/zsh-conf"

    rm -rf ${zsh_loc}

    git clone --recursive git@github.com:EduardoNeville/zsh-conf.git ${zsh_loc}

    # Remove previous file
    rm -rf "${HOME}/.zshrc"

    # Create symbolic link
    ln -fs "${zsh_loc}/.zshrc" "${HOME}/.zshrc"

    _process "-> Sourcing your zsh config"

    source $HOME/.zshrc
}

# ---
# Installing packer
# ---

install_packer(){
    _process "Installing NeoVim Packer"
    rm -rf ~/.local/share/nvim/site/pack/packer/start
    git clone --depth 1 https://github.com/wbthomason/packer.nvim\
    ~/.local/share/nvim/site/pack/packer/start/packer.nvim
}

install_nvim_plugins(){

    _process "-> Installing Copilot"

    rm -rf ~/.config/nvim/pack/github/start/copilot.vim

    git clone https://github.com/github/copilot.vim ~/dotfiles/configs/nvim/pack/github/start/copilot.vim
}


# ---
# Nix Package Manager Install
# ---
nix_install(){
    _process "-> Installing Nix Package Manager"
    _installBase
    _installNix
}


# ----------------------------------------------------------------------------------------
# The install
# ----------------------------------------------------------------------------------------
install(){
    # Package Managers
    macOSarr=(install_homebrew brew_backup_new_packages brew_installing_packages)
    nixPkg=(nix_install)
    aptPkg=(apt_install_pkgs)
    pkg_arr=(macOSarr nixPkg aptPkg)

    buf_arr=()

    printf "Press one or more to install \n"
    printf "Press i for install $(tput setaf 1)pkgs $(tput sgr0) \n"
    printf "Press s for $(tput setaf 2)symlink $(tput sgr0) \n"
    printf "Press z for $(tput setaf 3)zsh plugins $(tput sgr0) \n"
    printf "Press p for $(tput setaf 4)packer$(tput sgr0) \n"
    printf "Press n for $(tput setaf 5)nvim plugins$(tput sgr0) \n"
    printf "Press a for $(tput setaf 6)all$(tput sgr0) \n"
    read -n 1 ans
    printf "\n"
    if [[ "$ans" == *"i"* ]] || [[ "$ans" == *"a"* ]]; then
        printf "What is your package manager? \n"
        printf "0-$(tput setaf 3) brew$(tput sgr0) \n"
        printf "1-$(tput setaf 5) nix$(tput sgr0) \n"
        printf "2-$(tput setaf 6) apt$(tput sgr0) \n"

        read -n 1 pkg
        printf "\n"
        if [[ "$pkg" == "0" ]]; then
            buf_arr=${macOSarr}
            echo "buf_arr: ${buf_arr}"
        elif [[ "$pkg" == "1" ]]; then
            buf_arr=${nixPkg}
        elif [[ "$pkg" == "2" ]]; then
            buf_arr=${aptPkg}
        fi


        if [[ "$ans" == "a" ]]; then 
		echo $ans
            link_dotfiles
        fi

	if [[ "$pkg" == "1" ]]; then 
		_process "-> Install base pkgs for apt"
		sudo apt install curl vim git
	fi

        for fnc in "${buf_arr[@]}"
        do
            ${fnc}
        done
    fi

    # Zsh plugin install
    if [[ "$ans" == *"z"* ]]; then 
	    echo "$ans"
	   zsh_plugins
    fi
    $link_dotfiles

    # Link dotfiles
    if [[ "$ans" == *"s"* ]]; then 
        link_dotfiles
    fi

    # Packer install
    if [[ "$ans" == *"p"* ]]; then 
        install_packer
    fi

    # Nvim plugins
    if [[ "$ans" == *"n"* ]]; then 
        install_nvim_plugins
    fi
}

# ---
# What we want to install
# ---
precise_install(){
    echo " What do you want to install "
    for dwnld in "${dwld_arr[@]}"
    do
	echo " $dwnld "
    done
    
    for dwnld in "${dwld_arr[@]}"
    do
        echo -n " Download $dwnld [y/n]: "
        read -n 1 ans
        printf '\n' 
        if [[ "$ans" == "y" ]]; then
            buf_arr+=("$dwnld")
        fi
    done

    for buff in "${buf_arr[@]}"
    do
        $buff
    done

    #Clean the buffer
    buf_arr=()
}

install
#precise_install
