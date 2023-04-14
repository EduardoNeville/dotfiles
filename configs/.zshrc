# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# ChatGPT OPENAI_API_KEY
file_content=$(cat /usr/local/opt/dotfiles/openAI_key.txt)
export OPENAI_API_KEY="$file_content"

source "$HOME/.cargo/env"


# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="powerlevel10k/powerlevel10k"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git zsh-autosuggestions zsh-syntax-highlighting web-search)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
 if [[ -n $SSH_CONNECTION ]]; then
   export EDITOR='nvim'
 else
   export EDITOR='nvim'
 fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
if command -v pyenv 1>/dev/null 2>&1; then
  eval "$(pyenv init -)"
fi
bindkey -v
export CLICOLOR=1


# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
# 
# SHORTCUTS
#
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
#



# --------------------------------------------------------------------------------
# --------------------------------------------------------------------------------
#
#  cd shortcuts
#
# --------------------------------------------------------------------------------
# --------------------------------------------------------------------------------
alias .1="cd .."
alias .2="cd ../.."
alias .3="cd ../../.."



# --------------------------------------------------------------------------------
# --------------------------------------------------------------------------------
#
# ls shortcuts
#
# --------------------------------------------------------------------------------
# --------------------------------------------------------------------------------

alias ls="exa --icons --tree --level=2 --sort='size' --reverse -a -I '.git|__pycache__|.mypy_cache|.ipynb_checkpoints'"
alias ls3="exa --icons --tree --level=3 --sort='size' --reverse -a -I '.git|__pycache__|.mypy_cache|.ipynb_checkpoints'"
alias ls4="exa --icons --tree --level=4 --sort='size' --reverse -a -I '.git|__pycache__|.mypy_cache|.ipynb_checkpoints'"

alias lshelp="echo '%%%%%%%%%%%%%%%%%%%%%%%%%% 
ls COMMANDS 
%%%%%%%%%%%%%%%%%%%%%%%%%% \n 
ls  -> exa all files in a tree of depth 2 sorted by size \n 
ls3 -> exa all files in a tree of depth 3 sorted by size \n 
ls4 -> exa all files in a tree of depth 4 sorted by size \n" 

alias nnn='nnn -c'
eval $(thefuck --alias)

# --------------------------------------------------------------------------------
# --------------------------------------------------------------------------------
#
# fzf shortcuts
#
# --------------------------------------------------------------------------------
# --------------------------------------------------------------------------------

_fzf_comprun() {
  local command=$1
  shift

  case "$command" in
    cd)           cd "$(find . -type d -print 2>/dev/null | fzf --height=40% --preview 'exa --icons --tree --level=2 --sort=size --reverse -a -I ".git|__pycache__|.mypy_cache|.ipynb_checkpoints" {}')" ;;
    *)            fzf "$@" ;;
  esac
}

alias fp="fzf --preview 'bat --style=numbers --color=always --line-range :500 {}'"

# !!!!!!!!!!!!!!!!!!!!!!!! DO NOT REPLICATE FOR ALL DEVICES THIS ONLY WORKS ON MY MAC 
#lib_mus =! -path ~/Library/* ! -path ~/Music/?*
#-not -path "./directory/*"
#!-path ~/.node-gyp/* not -path "~/Music/*"
#!-path ~/.node-gyp/* !-path ~/Music/* !-path ~/Documents/* !-path ~/Animation/*

alias fcd="_fzf_comprun cd"

alias fzfhelp="echo '%%%%%%%%%%%%%%%%%%%%%%%%%% 
fzf COMMANDS 
%%%%%%%%%%%%%%%%%%%%%%%%%% \n 
fp -> fzf preview with bat \n 
fcd -> cd from current dir using the fexa cmd \n" 


# --------------------------------------------------------------------------------
# --------------------------------------------------------------------------------
#
# Git shortchuts
#
# --------------------------------------------------------------------------------
# --------------------------------------------------------------------------------
alias ga='git add .'
alias gc='git commit'
alias gac='git add . && git commit'
alias gps='git push'
alias gpl='git pull'
alias gf='git fetch'
alias gstat='git status'
alias gstsh='git stash'
alias gco='git checkout'
alias ghelp="echo '%%%%%%%%%%%%%%%%%%%%%%%%%% 
github COMMANDS 
%%%%%%%%%%%%%%%%%%%%%%%%%% 
ga -> git add . \n 
gc -> git commit \n
gac -> git add . && git commit \n 
gps -> git push \n
gpl -> git pull \n
gf -> git fetch \n
gstat -> git status \n
gstsh -> git stash \n
gco -> git checkout\n'"


# --------------------------------------------------------------------------------
# --------------------------------------------------------------------------------
#
# Help 
#
# --------------------------------------------------------------------------------
# --------------------------------------------------------------------------------
alias sclist='ghelp;fzfhelp;lshelp' 

