# /install
#!/usr/bin/env bash

# Detect the operating system
if [[ "$(uname)" == "Linux" ]]; then
    DOTFILES_DIR="/root/dotfiles"  # Linux root directory
    PACKAGE_MANAGER="apt"
else
    DOTFILES_DIR="${HOME}/Library/dotfiles"  # macOS
    PACKAGE_MANAGER="brew"
fi

LOG="${HOME}/Library/Logs/dotfiles.log"
GITHUB_USER=EduardoNeville
GITHUB_REPO=dotfiles
DIR="${DOTFILES_DIR}/${GITHUB_REPO}"


_process() {
    echo "$(date) PROCESSING:  $@" >> $LOG
    printf "$(tput setaf 6) %s...$(tput sgr0)\n" "$@"
}

_success() {
    local message=$1
    printf "%s✓ Success:%s\n" "$(tput setaf 2)" "$(tput sgr0) $message"
}

download_dotfiles() {
    _process "→ Creating directory at ${DIR} and setting permissions"
    mkdir -p "${DIR}"

    _process "→ Downloading repository to /tmp directory"
    curl -#fLo /tmp/${GITHUB_REPO}.tar.gz "https://github.com/${GITHUB_USER}/${GITHUB_REPO}/tarball/main"

    _process "→ Extracting files to ${DIR}"
    tar -zxf /tmp/${GITHUB_REPO}.tar.gz --strip-components 1 -C "${DIR}"

    _process "→ Removing tarball from /tmp directory"
    rm -rf /tmp/${GITHUB_REPO}.tar.gz

    [[ $? ]] && _success "${DIR} created, repository downloaded and extracted"

    # Change to the dotfiles directory
    cd "${DIR}"
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

# /install
link_dotfiles() {
	 # symlink files to the HOME directory.
	 if [[ -f "${DIR}/opt/files" ]]; then
		_process "→ Symlinking dotfiles in /configs"

		# Set variable for list of files
		files="${DIR}/opt/files"

		# Store IFS separator within a temp variable
		OIFS=$IFS
		# Set the separator to a carriage return & a new line break
		# read in passed-in file and store as an array
		IFS=$'\r\n'
		links=($(cat "${files}"))

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
		# Remove previos file
		rm -rf "${HOME}/${file[1]}"
		# Create symbolic link
		ln -fs "${DIR}/${file[0]}" "${HOME}/${file[1]}"
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

# /install
install_homebrew() {
    _process "→ Installing Homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"

    _process "→ Running brew doctor"
    brew doctor
    [[ $? ]] \
    && _success "Installed Homebrew"
}

install_formulae() {
if [ "$PACKAGE_MANAGER" == "brew" ]; then
    if ! type -P 'brew' &> /dev/null; then
        _error "Homebrew not found"
    else
        _process "→ Installing Homebrew packages"

        # Set variable for list of homebrew formulaes
        taps="${DIR}/opt/brew_tap"
        brews="${DIR}/opt/homebrew"


        # Update and upgrade all packages
        _process "→ Updating and upgrading Homebrew packages"
        brew update
        brew upgrade

        # Tap some necessary formulae
        _process "-> Checking status of brew taps "
        # Set the separator to a carriage return & a new line break
        # read in passed-in file and store as an array
        IFS=$'\r\n' brew_taps=($(cat "${taps}"))

        # Loop through split list of brew_taps
        _process "→ Checking status of desired Homebrew brew_taps"
        for index in ${!brew_taps[*]}
        do
            # Test whether a Homebrew formula is already installed
            echo "→ Checking status of ${brew_taps[$index]}"
            program_exists "${brew_taps[$index]}" || brew tap "${brew_taps[$index]}"
            if ! brew list ${brew_taps[$index]} &> /dev/null; then
              echo "→ Installing ${brew_taps[$index]}"
              brew install ${brew_taps[$index]}
            fi
        done

        # Store IFS within a temp variable
        OIFS=$IFS

        # Set the separator to a carriage return & a new line break
        # read in passed-in file and store as an array
        IFS=$'\r\n' formulae=($(cat "${brews}"))

        # Loop through split list of formulae
        _process "→ Checking status of desired Homebrew formulae"
        for index in ${!formulae[*]}
        do
            # Test whether a Homebrew formula is already installed
            echo "→ Checking status of ${formulae[$index]}"
            program_exists "${formulae[$index]}" || brew install "${formulae[$index]}"
            if ! brew list ${formulae[$index]} &> /dev/null; then
              echo "→ Installing ${formulae[$index]}"
              brew install ${formulae[$index]}
            fi
        done

        # Reset IFS back
        IFS=$OIFS

        brew cleanup

        [[ $? ]] && _success "All Homebrew packages installed and updated"
    fi
elif [ "$PACKAGE_MANAGER" == "apt" ]; then
    if ! type -P 'apt' &> /dev/null; then
        _error "apt not found"
    else
        _process "→ Installing apt packages"
        # Set variable for list of apt packages
        packages="${DIR}/opt/apt"
        echo "${DIR}"
        # Update and upgrade all packages
        _process "→ Updating and upgrading apt packages"
        sudo apt update
        sudo apt upgrade
        # Store IFS within a temp variable
        OIFS=$IFS
        # Set the separator to a carriage return & a new line break
        # read in passed-in file and store as an array
        IFS=$'\r\n' formulae=($(cat "${packages}"))
        # Loop through split list of formulae
        _process "→ Checking status of desired apt packages"
        for index in ${!formulae[*]}
        do
            # Test whether an apt package is already installed
            echo "→ Checking status of ${formulae[$index]}"
            dpkg -s "${formulae[$index]}" >/dev/null 2>&1 || sudo apt install "${formulae[$index]}"
        done
        # Reset IFS back
        IFS=$OIFS
        sudo apt autoremove
        [[ $? ]] && _success "All apt packages installed and updated"
    fi
fi

}

install_zsh_plugins(){
    _process "→ Installing ZSH Plugins"
    zsh_plugins="${DIR}/opt/zsh_plugins"
    # Set the separator to a carriage return & a new line break
    # read in passed-in file and store as an array
    IFS=$'\r\n' zsh_clone_names=($(cat "${zsh_plugins}"))

    for i in "${!zsh_clone_names[@]}"
    do
        IFS="/" read user zsh_plugin_name <<< "${zsh_clone_names[$i]}"
        _process "[$i / ${#zsh_clone_names[@]}] -> Checking if ${zsh_plugin_name} is installed"

        #if [[ -d ~/.config/zsh/plugins/${zsh_plugin_name}/${zsh_plugin_name}.plugin.zsh]] then
        #    _process "→ ${zsh_plugin_name} is already installed"
        #else
            _process "→ Installing ${zsh_plugin_name}"
            git clone git@github.com:${zsh_clone_names[$i]}.git ~/.config/zsh/plugins/${zsh_plugin_name}
        #fi
    done

}

install_packer(){
    _process "Installing packer"
    rm -rf ~/.local/share/nvim/site/pack/packer/start
    git clone --depth 1 https://github.com/wbthomason/packer.nvim\
    ~/.local/share/nvim/site/pack/packer/start/packer.nvim
}

install_nvim_plugins(){
    _process "Installing NeoVim plugins"
    nvim --headless -c 'autocmd User PackerComplete quitall' -c 'silent PackerSync'
}

dwld_arr=( download_dotfiles link_dotfiles install_homebrew install_formulae install_packer install_nvim_plugins) #install_zsh_plugins)

buf_arr=()
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
#install
