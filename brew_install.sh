#!/usr/bin/env bash
# Author: Eduardo <eduardo.nevillecastro@epfl.ch
# Description:
# Automatically install tools for different OS

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

# Assert the special programs must exist.
function program_must_exist() {
    program_exists $1

    # throw error on non-zero return value
    if [ "$?" -ne 0 ]; then
        error "You must have '$1' installed to continue."
    fi
}

# Install packages which don't provide binary package by git.
function git_install() {
    program_must_exist "git"

    #git clone -b master git@github.com:clvv/fasd.git /tmp/fasd
    cd /tmp/fasd || exit
    sudo make install
}

# Install package by brew(For MacOs)
function brew_install() {
        type brew>/dev/null 2>&1 || {
                echo >&2 " require brew but it's not installed.  Aborting.";
                exit 1; }
        # Install command if not exist
        echo "start install pyenv"
        program_exists "pyenv" || brew install pyenv

        echo "start install nnn"
        program_exists "nnn" || brew install nnn 

        echo "start install tree-sitter"
        program_exists "tree-sitter" || brew install tree-sitter 
 
        echo "start install scala"
        program_exists "scala" || brew install scala
        
        echo "start install sbt"
        program_exists "sbt" || brew install sbt  
        
        echo "start install openjdk"
        program_exists "openjdk" || brew install openjdk  
            
        echo "start install curl"
        program_exists "curl" || brew install curl 

        echo "start install nvc"
        program_exists "nvc" || brew install nvc 

        echo "start install luajit"
        program_exists "luajit" || brew install luajit 

        echo "start install openssl@3"
        program_exists "openssl@3" || brew install openssl@3 

        echo "start install node"
        program_exists "node" || brew install node 

        echo "start install gdb"
        program_exists "gdb" || brew install gdb 

        echo "start install neovim"
        program_exists "neovim" || brew install neovim 

        echo "start install neofetch"
        program_exists "neofetch" || brew install neofetch

        echo "start install cmake"
        program_exists "cmake" || brew install cmake 

        echo "start install pkg-config"
        program_exists "pkg-config" || brew install pkg-config 

        echo "start install nvm"
        program_exists "nvm" || brew install nvm
        
        # ----------------------------------
        # ----------------------------------
        # CASKS
        # ----------------------------------
        # ----------------------------------
        
        echo "start install wezterm"
        program_exists "wezterm" || brew install wezterm 

        echo "start install font-hack-nerd-font"
        program_exists "font-hack-nerd-font" || brew install font-hack-nerd-font
        
}

function pip_install() {
        program_must_exist "pip"
        
        echo "start install beautifulsoup4"
        program_exists "beautifulsoup4" || pip install beautifulsoup4 

        echo "start install pandas"
        program_exists "pandas" || pip install pandas 

        echo "start install numpy"
        program_exists "numpy" || pip install numpy 

        echo "start install openai"
        program_exists "openai" || pip install openai 

        echo "start install matplotlib"
        program_exists "matplotlib" || pip install matplotlib

        echo "start install MarkupSafe"
        program_exists "MarkupSafe" || pip install MarkupSafe

        echo "start install scipy"
        program_exists "scipy" || pip install scipy

        echo "start install websockets"
        program_exists "websockets" || pip install websockets
}


