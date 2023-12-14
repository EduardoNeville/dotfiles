# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
# 
# p10k SETUP 
#
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
#if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
#  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
#fi
#export ZSH=$HOME/.zsh
#typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet
#
## If you come from bash you might have to change your $PATH.
## export PATH=$HOME/bin:/usr/local/bin:$PATH
#
## Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"
#
## To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
if command -v pyenv 1>/dev/null 2>&1; then
    eval "$(pyenv init -)"
fi

ZSH_THEME="powerlevel10k/powerlevel10k"
#"minimal"
#"jonathan"
#"powerlevel10k/powerlevel10k"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes

plugins=(git zsh-autosuggestions zsh-syntax-highlighting web-search fzf-tab)

source $ZSH/oh-my-zsh.sh


# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
# 
# ChatGPT API KEY SETUP 
#
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

# ChatGPT OPENAI_API_KEY
file_content=$(cat ~/openAI_key.txt)
export OPENAI_API_KEY="$file_content"

source "$HOME/.cargo/env"

# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#
# PATH SETUP
#
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


# Preferred editor for local and remote sessions
 if [[ -n $SSH_CONNECTION ]]; then
    export EDITOR='nvim'
 else
    export EDITOR='nvim'
 fi

bindkey -v
export CLICOLOR=1

# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
# 
# fzf-tab SETUP 
#
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

# disable sort when completing `git checkout`
zstyle ':completion:*:git-checkout:*' sort false
# set descriptions format to enable group support
zstyle ':completion:*:descriptions' format '[%d]'
# set list-colors to enable filename colorizing
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
# preview directory's content with exa when completing cd
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'exa -1 --color=always $realpath' # remember to use single quote here!!!
# switch group using `,` and `.`
zstyle ':fzf-tab:*' switch-group ',' '.'
# fzf-bindings
zstyle ':fzf-tab:*' fzf-bindings 'ctrl-j:toggle' 'ctrl-a:accept' 'ctrl-a:toggle-all'

# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
# 
# NNN SETUP 
#
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
export NNN_PLUG='p:preview-tui;f:fzcd;g:gitroot;c:cdpath'

export NNN_FIFO='/tmp/nnn.fifo'
export NNN_USE_EDITOR='nvim'
export NNN_ICONS=".config/icons-in-terminal"
alias nnn='nnn -P p'

# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
# POMODORO
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
alias pom='~/.config/pomodoro/pomodoro'

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
#  rm shortcuts
#
# --------------------------------------------------------------------------------
# --------------------------------------------------------------------------------
alias del="rm -rf"

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
alias lsn="exa --icons --tree --level=2 --sort='name' --reverse -a -I '.git|__pycache__|.mypy_cache|.ipynb_checkpoints'"

alias lshelp="echo '%%%%%%%%%%%%%%%%%%%%%%%%%% 
ls COMMANDS 
%%%%%%%%%%%%%%%%%%%%%%%%%% \n 
ls  -> exa all files in a tree of depth 2 sorted by size \n 
ls3 -> exa all files in a tree of depth 3 sorted by size \n 
ls4 -> exa all files in a tree of depth 4 sorted by size \n" 

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
        cd)           cd "$(find . -type d \( -name .git -o -name __pycache__ -o -name .mypy_cache -o -name .ipynb_checkpoints \) -prune -o -print | fzf --preview 'exa --icons --tree --level=2 --sort=size --reverse -a -I ".git|__pycache__|.mypy_cache|.ipynb_checkpoints" {}')" ;;
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
#  Other  
#
# --------------------------------------------------------------------------------
# --------------------------------------------------------------------------------

alias whatsapp='cd ~/.config/WhatsGo/ && go run .'



# --------------------------------------------------------------------------------
# --------------------------------------------------------------------------------
#
# Help 
#
# --------------------------------------------------------------------------------
# --------------------------------------------------------------------------------
alias sclist='ghelp;fzfhelp;lshelp' 

export PATH=$PATH:/Users/eduardoneville82/.spicetify

