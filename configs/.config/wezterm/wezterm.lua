local wezterm = require("wezterm")

---------------------------------------------------------------
--- Config
---------------------------------------------------------------
local config = {
	check_for_updates = false,
        -- https://github.com/tonsky/FiraCode
	font = wezterm.font('Fira Code', {weight="Regular", stretch='Normal', style='Normal'}),
        font = wezterm.font_with_fallback {'Fira Code'},
        font_size = 15,

        -- Default colours
        --color_scheme = "Catppuccin", -- Machiatto
	color_scheme = "Tokyo Night Storm",	
	--color_scheme_dirs = { os.getenv("HOME") .. "/.config/wezterm/colors/" },
	
	--------------
	---- TAB BAR
	--------------
	window_background_opacity = 0.92,
	window_decorations = "RESIZE",
	hide_tab_bar_if_only_one_tab = true,
	scrollback_lines = 5000,
	tab_bar_style = "custom",
    	tab_bar_colors = {
		bg_color = "#00000000", -- transparent background
		inactive_tab_fg_color = "#bbbbbb", -- inactive tab foreground
		inactive_tab_bg_color = "#00000000", -- inactive tab background (transparent)
		active_tab_fg_color = "#ffffff", -- active tab foreground
		active_tab_bg_color = "#00000000", -- active tab background (transparent)
	}
}

return config
