### ---- PATH config ----------------------------------------
export PATH=$HOME/bin:/usr/local/bin:$PATH

### ZSH HOME
export ZSH=$HOME/.config/zsh

### ---- history config -------------------------------------
export HISTFILE=$ZSH/.zsh_history

# How many commands zsh will load to memory.
export HISTSIZE=10000

# How many commands history will save on file.
export SAVEHIST=10000

# History won't save duplicates.
setopt HIST_IGNORE_ALL_DUPS

# History won't show duplicates on search.
setopt HIST_FIND_NO_DUPS

### ----- configs ------------------------------------------
#bindkey -v
export CLICOLOR=1

# cd without cd 
setopt autocd 
### ----- Completion init -----------------------------------
if type brew &>/dev/null; then
    FPATH=$(brew --prefix)/share/zsh-completions:$FPATH

    autoload -Uz compinit
    compinit -i
    
fi

### ---- Plugins & Themes -----------------------------------

# ZSH PLUGINS
fpath=($ZSH/plugins/zsh-completions/src $fpath)
source $ZSH/plugins/fzf-tab/fzf-tab.plugin.zsh
source $ZSH/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
source $ZSH/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source $ZSH/plugins/zsh-fzf-history-search/zsh-fzf-history-search.zsh

# ZSH THEMES
#source $ZSH/themes/spaceship-zsh-theme/spaceship.zsh-theme
source ~/powerlevel10k/powerlevel10k.zsh-theme

### ---- Powerlevel10k config -------------------------------
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

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
## To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
if command -v pyenv 1>/dev/null 2>&1; then
    eval "$(pyenv init -)"
fi

ZSH_THEME="powerlevel10k/powerlevel10k"

### ----- ChatGPT config ------------------------------------------# ChatGPT OPENAI_API_KEY
export OPENAI_API_KEY="$(cat $HOME/OPENAI_API_KEY.txt)"


### ----- fzf-tab config ------------------------------------------
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
zstyle ':fzf-tab:*' fzf-bindings 'space:toggle' 'ctrl-a:accept' 'ctrl-A:toggle-all'

### ------
### --- Aliases -----------------
### ------

### ----- zoxide config ------------------------------------------
# Preview all past directories stored in zoxide
zq_cd() {
    local dir
    dir=$(zoxide query --interactive)
    if [ -n "$dir" ]; then
        cd "$dir"
    fi
}
alias zq='zq_cd'

alias zhelp="echo '%%%%%%%%%%%%%%%%%%%%%%%%%% 
zoxide COMMANDS 
%%%%%%%%%%%%%%%%%%%%%%%%%% \n 
zq -> zoxide query --interactive and cd there \n'"

# ----- NNN SETUP -------------------------------
export NNN_PLUG='p:preview-tui;f:fzcd;g:gitroot;c:cdpath;a:autojump'
export NNN_FIFO='/tmp/nnn.fifo'
export NNN_USE_EDITOR='nvim'
export NNN_ICONS=".config/icons-in-terminal"
alias nnn='nnn'

#{XDG_CONFIG_HOME:-$HOME/.config}/nnn/.lastd
#
## Quit nnn after chdir
#if [ -f /usr/share/nnn/quitcd/quitcd.bash_zsh ]; then
#    source /usr/share/nnn/quitcd/quitcd.bash_zsh
#fi

# ---
# --- CLI -----------------------------------
# ---

# --- POMODORO ------------------------------
alias pom='~/.config/pomodoro/pomodoro'

# --- BARD ----------------------------------
alias bc='bard-cli'

# -------------------------------  
# --- SHORTCUTS -----------------
# -------------------------------

# --- rm shortcuts -------------------------------
alias del="rm -rf"

# --- cd shortcuts -------------------------------
alias .1="cd .."
alias .2="cd ../.."
alias .3="cd ../../.."

# --- ls shortcuts -------------------------------
alias ls0="exa --icons --tree --level=1 --sort='size' --reverse -a -I '.git|__pycache__|.mypy_cache|.ipynb_checkpoints|node_modules'"
alias ls="exa  --icons --tree --level=2 --sort='size' --reverse -a -I '.git|__pycache__|.mypy_cache|.ipynb_checkpoints|node_modules'"
alias ls3="exa --icons --tree --level=3 --sort='size' --reverse -a -I '.git|__pycache__|.mypy_cache|.ipynb_checkpoints|node_modules'"
alias ls4="exa --icons --tree --level=4 --sort='size' --reverse -a -I '.git|__pycache__|.mypy_cache|.ipynb_checkpoints|node_modules'"
alias lsn="exa --icons --tree --level=2 --sort='name' --reverse -a -I '.git|__pycache__|.mypy_cache|.ipynb_checkpoints|node_modules'"

alias lshelp="echo '%%%%%%%%%%%%%%%%%%%%%%%%%% 
ls COMMANDS 
%%%%%%%%%%%%%%%%%%%%%%%%%% \n 
ls  -> exa all files in a tree of depth 2 sorted by size \n 
ls3 -> exa all files in a tree of depth 3 sorted by size \n 
ls4 -> exa all files in a tree of depth 4 sorted by size \n'" 


# --- fzf shortcuts -------------------------------
fzf_cd() {
    local dir
    dir=$(fd --type d --hidden --exclude .git | fzf-tmux -p 90%,80% --reverse --preview "exa --icons --tree --level=1 --reverse -a {}")
    if [ -n "$dir" ]; then
        cd "$dir"
    fi
}

alias fp='fd --type file --hidden --exclude .git | fzf-tmux -p 80%,80%  --reverse --preview "bat --style=numbers --color=always {}" | xargs nvim'
alias fcd='fzf_cd'
alias fzfhelp="echo '%%%%%%%%%%%%%%%%%%%%%%%%%% 
fzf COMMANDS 
%%%%%%%%%%%%%%%%%%%%%%%%%% \n 
fp -> fzf files with bat and open in nvim \n 
fcd -> cd from current dir \n" 


# --- Git shortchuts -------------------------------
alias ga='git add .'
alias gc='git commit'
alias gac='git add . && git commit'
alias gps='git push'
alias gpl='git pull'
alias gf='git fetch'
alias gl='git log'
alias gst='git status'
alias gss='git stash'
alias gco='git checkout'
alias lg='lazygit'
alias ghelp="echo '%%%%%%%%%%%%%%%%%%%%%%%%%% 
github COMMANDS 
%%%%%%%%%%%%%%%%%%%%%%%%%% 
ga -> git add . \n 
gc -> git commit \n
gac -> git add . && git commit \n 
gps -> git push \n
gpl -> git pull \n
gf -> git fetch \n
gl -> git log \n
gst -> git status \n
gss -> git stash \n
gco -> git checkout\n
lg -> lazygit\n'"

# --- Docker ----------------------------------
alias ld='lazydocker'

# --- evals config ----------------------------------
eval "$(zoxide init zsh)"

# --- tmux config ----------------------------------
export PATH="~/.tmuxifier/bin:$PATH"
eval "$(tmuxifier init -)"

#eval $(thefuck --alias)

# --- Other shortchuts -------------------------------
alias whatsapp='cd ~/.config/WhatsGo/ && go run .'

# --- Help -------------------------------
alias sclist='ghelp;fzfhelp;lshelp;zhelp' 
export PATH=$PATH:/Users/eduardoneville82/.spicetify

# bun completions
[ -s "/Users/eduardoneville82/.bun/_bun" ] && source "/Users/eduardoneville82/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
