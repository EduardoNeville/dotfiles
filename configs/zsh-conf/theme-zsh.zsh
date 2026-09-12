# theme-zsh.zsh — apply the shared light/dark theme to zsh plugins.
#
# Reads ~/.local/state/theme (written by wezterm's toggle_theme() and synced
# to remote hosts by configs/theme/scripts/propagate_state.sh) and applies the
# matching styles on every prompt (precmd hook):
#
#   - starship              → STARSHIP_PALETTE (palettes in starship.toml)
#   - fzf / fzf-tab / fzf-history-search → FZF_DEFAULT_OPTS
#   - zsh-autosuggestions   → ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE
#   - fast-syntax-highlighting → fast-theme CONFIG:dark|light
#     (themes in configs/zsh-conf/themes/f-sy-h/; symlinked to
#     ~/.config/f-sy-h — see the README in that directory)
#
# Styles are only re-applied when the theme actually changed, so the
# prompt stays cheap in steady state.

typeset -g _theme_state_file="${XDG_STATE_HOME:-$HOME/.local/state}/theme"
typeset -g _theme_applied=""

# ── Starship active config ──────────────────────────────────
# The installed starship build ignores STARSHIP_PALETTE and won't override a
# static root `palette` key at runtime (only a root `palette = "name"` line
# activates palette resolution; the STARSHIP_PALETTE env var does nothing).
# So we generate a tiny "active" config whose root `palette = "light"|"dark"`
# line follows ~/.local/state/theme, then point STARSHIP_CONFIG at it.
# Starship re-reads STARSHIP_CONFIG on every prompt (each prompt is a fresh
# subprocess), so the colors switch on the next prompt.
typeset -g _starship_template="${STARSHIP_TEMPLATE:-$HOME/dotfiles/configs/starship/starship.toml}"
[[ -r "$_starship_template" ]] || _starship_template="$HOME/.config/starship/starship.toml"
# Active config lives in the XDG state dir (alongside theme / theme-tmux-applied),
# NOT under ~/.config/starship (which is a symlink into the tracked dotfiles repo)
# — keeping it out of the repo keeps git clean while starship re-reads it each prompt.
typeset -g _starship_active="${XDG_STATE_HOME:-$HOME/.local/state}/starship-active.toml"

_starship_build_active() {
    local theme="$1"
    local tmp="$_starship_active.tmp"
    { printf 'palette = "%s"\n\n' "$theme"; cat "$_starship_template"; } > "$tmp" 2>/dev/null \
        && mv "$tmp" "$_starship_active" \
        && export STARSHIP_CONFIG="$_starship_active"
}

_theme_read() {
    local t
    [[ -r "$_theme_state_file" ]] || return 1
    t="$(< "$_theme_state_file")"
    [[ "$t" == "light" || "$t" == "dark" ]] || return 1
    print -r -- "$t"
}

_theme_apply() {
    local theme="$1"
    [[ "$theme" == "$_theme_applied" ]] && return 0
    _theme_applied="$theme"

    if [[ "$theme" == "light" ]]; then
        # starship: Catppuccin Latte palette (via generated active config)
        _starship_build_active light
        export STARSHIP_PALETTE="light"
        # fzf: light-friendly colors (dark text on transparent/light bg)
        export FZF_DEFAULT_OPTS='
--color=fg:#4c4f69,bg:-1,hl:#1e66f5
--color=fg+:#4c4f69,bg+:#ccd0da,hl+:#40a02b
--color=info:#8839ef,prompt:#df8e1d,pointer:#8839ef
--color=marker:#df8e1d,spinner:#8839ef,header:#179299'
        # zsh-autosuggestions: dark gray, clearly visible on light bg
        # (#333333 — pure black would be indistinguishable from typed text)
        ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#333333"
        # fast-syntax-highlighting: Catppuccin Latte styles
        if (( ${+functions[fast-theme]} )) \
            && [[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/f-sy-h/light.ini" ]]; then
            fast-theme -q CONFIG:light
        fi
    else
        # starship: Night Owl palette (via generated active config)
        _starship_build_active dark
        export STARSHIP_PALETTE="dark"
        # fzf: original dark colors
        export FZF_DEFAULT_OPTS='
--color=fg:#55a8fb,bg:-1,hl:#b9b1bc
--color=fg+:#55a8fb,bg+:-1,hl+:#0ae4a4
--color=info:#aa54f9,prompt:#ffd700,pointer:#FFFFFF
--color=marker:#ff00f6,spinner:#aa54f9,header:#f9f972'
        # zsh-autosuggestions: default dim gray
        ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=8"
        # fast-syntax-highlighting: Night Owl styles
        if (( ${+functions[fast-theme]} )) \
            && [[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/f-sy-h/dark.ini" ]]; then
            fast-theme -q CONFIG:dark
        fi
    fi
}

_theme_prompt_hook() {
    local theme
    theme="$(_theme_read)" || theme="dark"
    _theme_apply "$theme"
}
precmd_functions+=(_theme_prompt_hook)

# Apply once at startup so the first prompt already has the right theme.
_theme_prompt_hook
