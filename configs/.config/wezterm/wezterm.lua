local wezterm = require("wezterm")

---------------------------------------------------------------
--- Config
---------------------------------------------------------------
local config = {
	check_for_updates = false,

    -- https://github.com/tonsky/FiraCode
	font = wezterm.font('Fira Code', {weight="Regular", stretch='Normal', style='Normal'}),
    font_size = 16,

	-----------------------------------
	-----------------------------------
	-- Colour Schemes
	-----------------------------------
	-----------------------------------

	--color_scheme = "Catppuccin", -- Machiatto
	color_scheme = "Tokyo Night Storm",	
	color_scheme_dirs = { os.getenv("HOME") .. "/.config/wezterm/colors/" },
	-- Aesthetic Night Colorscheme
	bold_brightens_ansi_colors = true,

	-----------------------------------
	-----------------------------------
	-- UI 
	-----------------------------------
	-----------------------------------

	------
	-- Cursor style
	------
	default_cursor_style = "BlinkingUnderline",

	------
	-- Tab Bar
	------

	hide_tab_bar_if_only_one_tab = true,
	show_tab_index_in_tab_bar = false,
	tab_bar_at_bottom = true,

	------
	-- Window Info
	------

	window_background_opacity = 0.85,
	window_decorations = "RESIZE",
	scrollback_lines = 5000,

 	window_padding = {
		left = 0,
	    	right = 0,
	    	top = 10,
	    	bottom = 0,
	},

	------
	-- Window Frame
	------

	window_frame = {
		-- The overall background color of the tab bar when
		-- the window is focused
		active_titlebar_bg = '#191b28',

		-- The overall background color of the tab bar when
		-- the window is not focused
		inactive_titlebar_bg = '#1f2335',
		--active_tab_left = {
		--	chars = "▐▌",
		--	style = "Bold",
		--},
		--active_tab_right = {
		--	chars = "▐▌",
		--	style = "Bold",
		--},
		--inactive_tab_left = {
		--	chars = "▐▌",
		--	style = "Bold",
		--},
		--inactive_tab_right = {
		--	chars = "▐▌",
		--	style = "Bold",
		--},
	},
	colors = {
	  	tab_bar = {
			-- The active tab is the one that has focus in the window
			active_tab = {
				-- The color of the background area for the tab
				bg_color = "#24283b",
				-- The color of the text for the tab
				fg_color = "#7aa2f7",

				-- Specify whether you want "Half", "Normal" or "Bold" intensity for the
				-- label shown for this tab.
				-- The default is "Normal"
				intensity = 'Normal',

				-- Specify whether you want "None", "Single" or "Double" underline for
				-- label shown for this tab.
				-- The default is "None"
				underline = 'None',

				-- Specify whether you want the text to be italic (true) or not (false)
				-- for this tab.  The default is false.
				italic = false,

				-- Specify whether you want the text to be rendered with strikethrough (true)
				-- or not for this tab.  The default is false.
				strikethrough = false,
	    	},

			-- Inactive tabs are the tabs that do not have focus
			inactive_tab = {
			bg_color = "#1f2335",
			fg_color = "#545c7e",

			  -- The same options that were listed under the `active_tab` section above
			  -- can also be used for `inactive_tab`.
	    	},

			-- You can configure some alternate styling when the mouse pointer
			-- moves over inactive tabs
			inactive_tab_hover = {
				bg_color = '#1f2335',
				fg_color = '#7aa2f7',
				italic = true,

				-- The same options that were listed under the `active_tab` section above
				-- can also be used for `inactive_tab_hover`.
			},

			-- The new tab button that let you create new tabs
			new_tab = {
				bg_color = '#7aa2f7',
				fg_color = '#191b28',

				-- The same options that were listed under the `active_tab` section above
				-- can also be used for `new_tab`.
			},

			-- You can configure some alternate styling when the mouse pointer
			-- moves over the new tab button
			new_tab_hover = {
				bg_color = '#1f2335',
				fg_color = '#7aa2f7',
				italic = true,

				-- The same options that were listed under the `active_tab` section above
				-- can also be used for `new_tab_hover`.
			},
		},
	}
}

return config

