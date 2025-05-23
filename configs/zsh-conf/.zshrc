### ---- PATH config ----------------------------------------
export PATH=$HOME/bin:/usr/local/bin:$PATH
export PATH="$HOME/.local/bin:$PATH"

### ZSH HOME
export ZSH=$HOME/.config/zsh-conf

### ---- Editor ---------------------------------------------
export EDITOR='nvim'

### ---- history config -------------------------------------
export HISTFILE=$ZSH/.zsh_history

# How many commands zsh will load to memory.
export HISTSIZE=10000

# How many commands history will save on file.
export SAVEHIST=10000

# FZF Theme
export FZF_DEFAULT_OPTS='
--color=fg:#55a8fb,bg:-1,hl:#b9b1bc
--color=fg+:#55a8fb,bg+:-1,hl+:#0ae4a4
--color=info:#aa54f9,prompt:#ffd700,pointer:#FFFFFF
--color=marker:#ff00f6,spinner:#aa54f9,header:#f9f972
'

# History won't save duplicates.
setopt HIST_IGNORE_ALL_DUPS

# History won't show duplicates on search.
setopt HIST_FIND_NO_DUPS

### ----- configs ------------------------------------------
bindkey -v
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
source $ZSH/plugins/fast-syntax-highlighting/F-Sy-H.plugin.zsh
source $ZSH/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source $ZSH/plugins/zsh-fzf-history-search/zsh-fzf-history-search.zsh

### ----- ChatGPT config ------------------------------------------# ChatGPT OPENAI_API_KEY
export OPENAI_API_KEY="$(cat $HOME/OPENAI_API_KEY.txt)"

### ----- fzf-tab config ------------------------------------------
# disable sort when completing `git checkout`
zstyle ':completion:*:git-checkout:*' sort false
# set descriptions format to enable group support
zstyle ':completion:*:descriptions' format '[%d]'
# set list-colors to enable filename colorizing
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
# preview directory's content with eza when completing cd
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
# switch group using `,` and `.`
zstyle ':fzf-tab:*' switch-group ',' '.'
# fzf-bindings
zstyle ':fzf-tab:*' fzf-bindings 'space:toggle' 'ctrl-a:accept' 'ctrl-A:toggle-all'

### ------
### --- Aliases -----------------
### ------

### ----- zoxide config ------------------------------------------
# Preview all past directories stored in zoxide
zq_func() {
    dir=`zoxide query --interactive`
    if [ -n "${dir}" ]; then
        cd ${dir}
    fi
}
alias zq='zq_func'

alias zhelp="echo '%%%%%%%%%%%%%%%%%%%%%%%%%%
zoxide COMMANDS
%%%%%%%%%%%%%%%%%%%%%%%%%% \n
zq -> zoxide query --interactive and cd there \n'"

# ----- NNN SETUP -------------------------------
export NNN_PLUG='p:preview-tui;f:fzcd;g:gitroot;c:cdpath;a:autojump'
export NNN_FIFO='/tmp/nnn.fifo'
#export NNN_OPENER='~/.config/nnn/plugins/nuke'
#export NNN_USE_EDITOR='nvim'

#{XDG_CONFIG_HOME:-$HOME/.config}/nnn/.lastd
#
## Quit nnn after chdir
#if [ -f /usr/share/nnn/quitcd/quitcd.bash_zsh ]; then
#    source /usr/share/nnn/quitcd/quitcd.bash_zsh
#fi

# ---
# --- CLI -----------------------------------
# ---

# --- Markdown on zathura -------------------
mdtozar_func() {
  local file=$1
  if [ -f "$file" ]; then
    cat $file | pandoc -f markdown -t pdf | zathura -
  else
    echo "File $file does not exist"
  fi
}
alias mdtozar='mdtozar_func'

# -------------------------------
# --- SHORTCUTS -----------------
# -------------------------------

alias xo="xdg-open"

# --- cd shortcuts -------------------------------
alias .1="cd .."
alias .2="cd ../.."
alias .3="cd ../../.."
alias .4="cd ../../../.."
alias .5="cd ../../../../.."
alias .6="cd ../../../../../.."

# --- ls shortcuts -------------------------------
alias ls0="eza --icons --tree --level=1 --sort='size' --reverse -a -I '.git|__pycache__|.mypy_cache|.ipynb_checkpoints|node_modules'"
alias lse="eza  --icons --tree --level=2 --sort='size' --reverse -a -I '.git|__pycache__|.mypy_cache|.ipynb_checkpoints|node_modules'"
alias ls3="eza --icons --tree --level=3 --sort='size' --reverse -a -I '.git|__pycache__|.mypy_cache|.ipynb_checkpoints|node_modules'"
alias ls4="eza --icons --tree --level=4 --sort='size' --reverse -a -I '.git|__pycache__|.mypy_cache|.ipynb_checkpoints|node_modules'"
alias lsn="eza --icons --tree --level=2 --sort='name' --reverse -a -I '.git|__pycache__|.mypy_cache|.ipynb_checkpoints|node_modules'"
alias lss="dust -d 2 -z 5MB -brC"

alias lshelp="echo '%%%%%%%%%%%%%%%%%%%%%%%%%%
ls COMMANDS
%%%%%%%%%%%%%%%%%%%%%%%%%% \n
ls  -> eza all files in a tree of depth 2 sorted by size \n
ls3 -> eza all files in a tree of depth 3 sorted by size \n
ls4 -> eza all files in a tree of depth 4 sorted by size \n'"

export EZA_COLORS="*csv=32:*.md=38;5;141"

# --- tv shortcuts -------------------------------
alias fp='file=$(tv); [ -n "$file" ] && echo "$file"; nvim "$file"'
alias fcd='dir=$(tv dirs); [ -n "$dir" ] && echo "$dir"; z "$dir" || :'

# --- Tmux shortcuts -------------------------------
alias tmux="TERM=xterm-256color tmux"

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
alias gt='gitui'
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
gt -> git tui\n'"

# --- Docker ----------------------------------
alias ld='lazydocker'

# --- evals config ----------------------------------
eval "$(zoxide init zsh)"

# rust export
export PATH="$HOME/.cargo/bin:$PATH"

export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
if command -v pyenv 1>/dev/null 2>&1; then
    eval "$(pyenv init -)"
fi

autoload -U compinit; compinit -i

# Starship 
export STARSHIP_CONFIG=~/.config/starship/starship.toml
export STARSHIP_CACHE=~/.starship/cache
eval "$(starship init zsh)"

export WASMTIME_HOME="$HOME/.wasmtime"

export PATH="$WASMTIME_HOME/bin:$PATH"
