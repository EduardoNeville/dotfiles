local wezterm = require("wezterm")
local act = wezterm.action

----------------------------------------------------
--- Theme Switcher ---------------------------------
----------------------------------------------------

local dark_scheme = "Ayu Dark (Gogh)"
local light_scheme = "Papercolor Light (Gogh)"

local dark_window_frame = {
    active_titlebar_bg = '#171d23',
    inactive_titlebar_bg = '#1f2d38',
}

local light_window_frame = {
    active_titlebar_bg = '#ffffff',
    inactive_titlebar_bg = '#e4e4e4',
}

local function toggle_theme(window, _)
    local current_scheme = window:effective_config().color_scheme
    local overrides = window:get_config_overrides() or {}
    
    if current_scheme == dark_scheme then
        overrides.color_scheme = light_scheme
        overrides.window_frame = light_window_frame
        overrides.window_background_opacity = 1.0
        wezterm.log_info("Switched to light theme: " .. light_scheme)
    else
        overrides.color_scheme = dark_scheme
        overrides.window_frame = dark_window_frame
        overrides.window_background_opacity = 0.85
        wezterm.log_info("Switched to dark theme: " .. dark_scheme)
    end
    
    window:set_config_overrides(overrides)
end

---------------------------------------------------------------
--- Workspace ----------------------------------------------------
---------------------------------------------------------------
wezterm.on('update-right-status', function(window, pane)
    window:set_right_status(window:active_workspace())
end)

---------------------------------------------------------------
--- Config ----------------------------------------------------
---------------------------------------------------------------
local config = {
    check_for_updates = false,

    --- https://github.com/tonsky/FiraCode
    --- font = wezterm.font('Fira Code', {weight="Regular", stretch='Normal', style='Normal'}),
    font_size = 13,

    --- Colour Schemes ------------------
    --color_scheme = "Catppuccin", -- Machiatto
    --color_scheme = "Tokyo Night Storm",	
    --color_scheme = 'Andromeda',
    --color_scheme = 'Papercolor Light (Gogh)', -- "Aesthetic Night
    --color_scheme = "Abernathy",	
    --color_scheme = 'Ayu Mirage (Gogh)',
    --color_scheme = 'Ayu Dark (Gogh)',
    --color_scheme = 'Ayu Light (Gogh)',
    --color_scheme = 'Elio (Gogh)',
    --color_scheme = 'Matrix (terminal.sexy)',
    --color_scheme = "Eldritch",
    --color_scheme = "Scarlet Protocol",
    --
    -- SynthWave
    --color_scheme = "Synthwave (Gogh)",
    --color_scheme = "Synthwave Alpha (Gogh)",
    --color_scheme = "SynthwaveAlpha",
    color_scheme = dark_scheme,


    color_scheme_dirs = { os.getenv("HOME") .. "/.config/wezterm/colors/" },
    -- Aesthetic Night Colorscheme
    bold_brightens_ansi_colors = true,

    --- UI --------------------------------
    --- Underline ------
    underline_thickness = 0,

    --- Cursor style ---
    default_cursor_style = "BlinkingBlock",

    --- Tab Bar --------
    hide_tab_bar_if_only_one_tab = true,
    show_tab_index_in_tab_bar = true,
    tab_bar_at_bottom = true,

    --- Window Info ----
    window_background_opacity = 0.85,

    -- Default setting
    window_decorations = "NONE",

    scrollback_lines = 5000,

    window_padding = {
        left = 0,
        right = 0,
        top = 0,
        bottom = 0,
    },
}

--- Tab title
wezterm.on(
    'format-tab-title',
    function(tab, tabs, panes, config, hover, max_width)
        --local title = tab_title(tab)
        --local tabName = string.format("%s", tab.tab_title):split('(')[1]

        --if tab.is_active then
        --  return {
        --    { Text = tabName},
        --  }
        --end
        local nonActive = string.format("-[ %s ]-", tab.tab_index)
        return nonActive
    end
)

--- Window Frame ---
config.window_frame = {
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
    --- Theme Toggle --------------------
    { key = "l", mods = "CTRL|SHIFT", action = wezterm.action_callback(toggle_theme) },

    --- Theme Cycler --------------------
    -- Calling the themeCycler
    --{ key = "t", mods = "CTRL", action = wezterm.action_callback(themeCycler) },

    -- Debug Pane -----------------------
    { key = "Escape", mods = "CTRL",       action = wezterm.action.ShowDebugOverlay },

    --------------------
    -- Split Window
    --------------------

    -- Split Horizontal == <CTRL-Shift-v>
    { key = 'v',      mods = 'ALT|CTRL',   action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' }, },

    -- Split Vertical == <CTRL-Shift-s>
    { key = 's',      mods = 'ALT|CTRL',   action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' }, },

    -- Switch Between Windows <CTRL-n> = +1 and <CTRL-p> = -1
    { key = 'l',      mods = 'CTRL',       action = wezterm.action.ActivatePaneDirection "Right" },
    { key = 'h',      mods = 'CTRL',       action = wezterm.action.ActivatePaneDirection "Left" },
    { key = 'k',      mods = 'CTRL',       action = wezterm.action.ActivatePaneDirection "Up" },
    { key = 'j',      mods = 'CTRL',       action = wezterm.action.ActivatePaneDirection "Down" },

    -- Increase the size of the pane to the left
    { key = "h",      mods = "CTRL|SHIFT", action = wezterm.action { AdjustPaneSize = { "Left", 2 } } },
    -- Increase the size of the pane to the right
    { key = "l",      mods = "CTRL|SHIFT", action = wezterm.action { AdjustPaneSize = { "Right", 2 } } },
    -- Increase the size of the pane above
    { key = "k",      mods = "CTRL|SHIFT", action = wezterm.action { AdjustPaneSize = { "Up", 2 } } },
    -- Increase the size of the pane below
    { key = "j",      mods = "CTRL|SHIFT", action = wezterm.action { AdjustPaneSize = { "Down", 2 } } },

    -- Show Tab Navigator
    { key = 'i',      mods = 'CTRL|SHIFT', action = act.ShowTabNavigator, },

    -- Rotate panes Clockwise
    -- eg.
    -- | 1 | 2 | 3 | => | 3 | 1 | 2 |
    { key = 'b',      mods = 'CTRL|SHIFT', action = act.RotatePanes 'Clockwise' },


    -- Claude integration
    { key = 'c',      mods = 'CTRL|SHIFT', action = wezterm.action { SendString = "\x1b\r" } },
}

if wezterm.target_triple:find("darwin") then
    config.window_decorations = "RESIZE"
end

return config
