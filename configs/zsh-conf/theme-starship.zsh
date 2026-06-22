# ── Starship palette from shared theme state ──────────────
# Updates STARSHIP_PALETTE before each prompt so that every
# prompt render reflects the current light/dark state.
# The state file is written by wezterm's toggle_theme().
_update_starship_palette() {
    local theme_file="$HOME/.local/state/theme"
    if [[ -f "$theme_file" && -r "$theme_file" ]]; then
        local palette
        palette=$(< "$theme_file")
        if [[ "$palette" == "light" || "$palette" == "dark" ]]; then
            export STARSHIP_PALETTE="$palette"
        fi
    fi
}
precmd_functions+=(_update_starship_palette)
