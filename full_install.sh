#!/usr/bin/env bash
# Author: Eduardo Nevile <eduardo.nevillecastro@epfl.ch>
# Description:
# Automatically install tools for different OS

# TODO
# Link dotfiles [ ]
# Zsh exec [ ]
# Packer and NVIM setup [ ]
# Brew install of packages [X]

# ---------
# Detect the operating system
# ---------
if [[ "$(uname)" == "Linux" ]]; then
    DOTFILES_DIR="/root/dotfiles"  # Linux root directory
    PACKAGE_MANAGER="apt"
	--- Linux Install
	-- Continue here
else
    DOTFILES_DIR="${HOME}/dotfiles"  # macOS
    PACKAGE_MANAGER="brew"
	#macOS install
fi

LOG="${HOME}/Library/Logs/dotfiles.log"
GITHUB_USER=EduardoNeville
GITHUB_REPO=dotfiles

_process() {
    echo "$(date) PROCESSING:  $@" >> $LOG
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
	 if [[ -f "$DOTFILES_DIR/opt/files" ]]; then
		_process "→ Symlinking dotfiles in /configs"

		# Set variable for list of files
		files="$DOTFILES_DIR/opt/files"

		# Store IFS separator within a temp variable
		OIFS=$IFS
		# Set the separator to a carriage return & a new line break
		# read in passed-in file and store as an array
		IFS=$'\r\n'
		links=($(cat "${files}"))

		echo $links
		# Loop through array of files
		for index in ${!links[*]}
		do
			for link in ${links[$index]}
			do
				_process "→ Linking ${links[$index]}"
				# set IFS back to space to split string on
				IFS=$' '
				# create an array of line items
				file=(${links[$index]})
		# Remove previous file
		rm -rf "${HOME}/${file[1]}"
		# Create symbolic link
		ln -fs "${DOTFILES_DIR}/${file[0]}" "${HOME}/${file[1]}"
			done
			# set separater back to carriage return & new line break
			IFS=$'\r\n'
		done
		# Reset IFS back
		IFS=$OIFS
		source "${HOME}/.bash_profile"
		[[ $? ]] && _success "All files have been copied"
    fi
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
function backup_new_packages(){
	_process "-> Backing up new packages into $PACKAGE_MANAGER"
	case "$PACKAGE_MANAGER" in
		"brew")
			if ! type -P 'brew' &> /dev/null; then
				_error "Homebrew not found while backing up NEW PACKAGES"
			else
				_process "→ Backing up new packages in $DOTFILES_DIR/opt/Brewfile"
				brew bundle dump --file="opt/Brewfile" -fv
			fi
		;;
		"apt")
			if ! type -P 'apt' &> /dev/null; then
				_error "APT not found while backing up NEW PACKAGES"
			else
				_process "→ Backing up new packages"
				echo "Not ready"
			fi
		;;
		*)
			_error "No package manager found from $PACKAGE_MANAGER"
	esac
}

# ---
#Installing packages
# ---
function installing_packages(){
	_process "-> Installing up new packages into $PACKAGE_MANAGER"
	case "$PACKAGE_MANAGER" in
		"brew")
			if ! type -P 'brew' &> /dev/null; then
				_error "Homebrew not found while installing up NEW PACKAGES"
			else
				_process "→ Installing up new packages in $DOTFILES_DIR/opt/Brewfile"
				brew bundle --file="$DOTFILES_DIR/opt/Brewfile" -v 
			fi
		;;
		"apt")
			if ! type -P 'apt' &> /dev/null; then
				_error "APT not found while backing up NEW PACKAGES"
			else
				_process "→ Backing up new packages"
				echo "Not ready"
			fi
		;;
		*)
			_error "No package manager found from $PACKAGE_MANAGER"
	esac
}

# ---
#Installing zsh plugins
# ---
function zsh_plugins(){
	_process "-> Installing ZSH Plugins"
	zsh_plugins="$DOTFILES_DIR/opt/zsh_plugins"
    # Set the separator to a carriage return & a new line break
    # read in passed-in file and store as an array
    IFS=$'\r\n' zsh_clone_names=($(cat "${zsh_plugins}"))
	
    for i in "${!zsh_clone_names[@]}"
    do
        IFS="/" read user zsh_plugin_name <<< "${zsh_clone_names[$i]}"
        _process "[$i / ${#zsh_clone_names[@]}] -> Checking if ${zsh_plugin_name} is installed"
            _process "→ Installing ${zsh_plugin_name}"
            git clone git@github.com:${zsh_clone_names[$i]}.git ~/.config/zsh/plugins/${zsh_plugin_name}
	done

	_process "-> Installing Powerline10k"
	git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k
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
    _process "Installing NeoVim plugins"
    bat neoVimPlugins.md

    _process "-> Installing Copilot"
    git clone https://github.com/github/copilot.vim \
   ~/.config/nvim/pack/github/start/copilot.vim
}

# Buffer arrays
dwld_arr=(link_dotfiles install_homebrew backup_new_packages installing_packages zsh_plugins install_packer install_nvim_plugins)
buf_arr=()

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

precise_install
