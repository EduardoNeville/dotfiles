local wezterm = require("wezterm")

----------------------------------------------------
--- Theme Cycler -----------------------------------
----------------------------------------------------

    ---cycle through builtin dark schemes in dark mode, 
    ---and through light schemes in light mode
    --local function themeCycler(window, _)
    --	local allSchemes = wezterm.color.get_builtin_schemes()
    --	local currentMode = wezterm.gui.get_appearance()
    --	local currentScheme = window:effective_config().color_scheme
    --	local darkSchemes = {'Tokyo Night Storm', 'Catppuccin Machiatto'}
    --	local lightSchemes = {'Papercolor Light (Gogh)'}
    --
    --	for name, scheme in pairs(allSchemes) do
    --		local bg = wezterm.color.parse(scheme.background) -- parse into a color object
    --		---@diagnostic disable-next-line: unused-local
    --		local h, s, l, a = bg:hsla() -- and extract HSLA information
    --		if l < 0.4 then
    --			table.insert(darkSchemes, name)
    --		else
    --			table.insert(lightSchemes, name)
    --		end
    --	end
    --	local schemesToSearch = currentMode:find("Dark") and darkSchemes or lightSchemes
    --
    --	for i = 1, #schemesToSearch, 1 do
    --		if schemesToSearch[i] == currentScheme then
    --			local overrides = window:get_config_overrides() or {}
    --			overrides.color_scheme = schemesToSearch[i+1]
    --			wezterm.log_info("Switched to: " .. schemesToSearch[i+1])
    --			window:set_config_overrides(overrides)
    --			return
    --		end
    --	end
    --end

---------------------------------------------------------------
--- Config ----------------------------------------------------
---------------------------------------------------------------
local config = {
	check_for_updates = false,

    --- https://github.com/tonsky/FiraCode
    --- font = wezterm.font('Fira Code', {weight="Regular", stretch='Normal', style='Normal'}),
    font_size = 16,

	--- Colour Schemes ------------------
	--color_scheme = "Catppuccin", -- Machiatto
	--color_scheme = "Tokyo Night Storm",	
    --color_scheme = 'Andromeda',
	--color_scheme = 'Papercolor Light (Gogh)', -- "Aesthetic Night
    --color_scheme = "Abernathy",	
    color_scheme = "Aci (Gogh)",

	color_scheme_dirs = { os.getenv("HOME") .. "/.config/wezterm/colors/" },
	-- Aesthetic Night Colorscheme
	bold_brightens_ansi_colors = true,


	--- UI --------------------------------
    --- Underline ------
    underline_thickness = 5,

	--- Cursor style ---
	default_cursor_style = "BlinkingBlock",

	--- Tab Bar --------
	hide_tab_bar_if_only_one_tab = true,
	show_tab_index_in_tab_bar = false,
	tab_bar_at_bottom = true,

	--- Window Info ----
	window_background_opacity = 0.85,
	window_decorations = "RESIZE",
	scrollback_lines = 5000,

 	window_padding = {
		left = 20,
        right = 0,
        top = 10,
        bottom = 0,
	},

	--- Window Frame ---
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
}

config.colors = {
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
config.keys = {
    	--- Theme Cycler --------------------
    -- Calling the themeCycler
    --{ key = "t", mods = "CTRL", action = wezterm.action_callback(themeCycler) },

    -- Look up Scheme you switched to
    { key = "Escape", mods = "CTRL", action = wezterm.action.ShowDebugOverlay },
    {
    key = '%',
    mods = 'CTRL|SHIFT|ALT',
    action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' },
    },
}

return config

