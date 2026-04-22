local wezterm = require("wezterm")
local act = wezterm.action
local io = require("io")
local os = require("os")

----------------------------------------------------
--- Theme State File -------------------------------
----------------------------------------------------

local STATE_FILE = os.getenv("XDG_STATE_HOME")
if not STATE_FILE or STATE_FILE == "" then
    local home = os.getenv("HOME") or "/home/" .. (os.getenv("USER") or "user")
    STATE_FILE = home .. "/.local/state/theme"
else
    STATE_FILE = STATE_FILE .. "/theme"
end

local function read_theme_state()
    local f = io.open(STATE_FILE, "r")
    if f then
        local state = f:read("*a"):gsub("%s+", "")
        f:close()
        return state == "light"
    end
    return false
end

local function write_theme_state(is_light)
    local f = io.open(STATE_FILE, "w")
    if f then
        f:write(is_light and "light" or "dark")
        f:close()
    end
end

----------------------------------------------------
--- Theme Switcher ---------------------------------
----------------------------------------------------

local dark_scheme = "Ayu Dark (Gogh)"
local light_scheme = "Papercolor Light (Gogh)"

local dark_window_frame = {
    active_titlebar_bg = '#171d23',
    -- Keep the titlebar color consistent when the window is unfocused
    inactive_titlebar_bg = '#171d23',
}

local dark_colors = {
    background = '#171d23',
    foreground = '#bfbfbf',
    cursor_bg = '#bfbfbf',
    cursor_border = '#bfbfbf',
    selection_bg = '#33425c',
    selection_fg = '#bfbfbf',
    ansi = {
        '#171d23', -- black
        '#f07178', -- red
        '#aad94c', -- green
        '#ffcf67', -- yellow
        '#59a5f2', -- blue
        '#d39bd6', -- magenta
        '#6bc3d4', -- cyan
        '#bfbfbf', -- white
    },
    brights = {
        '#586975', -- bright black
        '#ff8e9e', -- bright red
        '#c2e68d', -- bright yellow
        '#ffe586', -- bright blue
        '#7aa9f7', -- bright magenta
        '#e78fd6', -- bright cyan
        '#9fd9e8', -- bright white
    },
}

local light_window_frame = {
    active_titlebar_bg = '#ffffff',
    -- Keep the titlebar color consistent when the window is unfocused
    inactive_titlebar_bg = '#ffffff',
}

local light_colors = {
    background = '#ffffff',
    foreground = '#333333',
    cursor_bg = '#333333',
    cursor_border = '#333333',
    selection_bg = '#b3d9ff',
    selection_fg = '#333333',
    ansi = {
        '#333333', -- black
        '#cc2222', -- red
        '#22aa22', -- green
        '#ccaa22', -- yellow
        '#2255cc', -- blue
        '#aa2255', -- magenta
        '#22aaaa', -- cyan
        '#dddddd', -- white
    },
    brights = {
        '#555555', -- bright black
        '#ff4444', -- bright red
        '#44cc44', -- bright green
        '#ffee44', -- bright yellow
        '#4488ff', -- bright blue
        '#ff44aa', -- bright magenta
        '#44ffff', -- bright cyan
        '#ffffff', -- bright white
    },
    indexed = { [16] = '#cc8800', [17] = '#444444' },
    scrollbar_thumb = '#cccccc',
    split = '#dddddd',
    tab_bar = {
        active_tab = { bg_color = '#ffffff', fg_color = '#333333' },
        inactive_tab = { bg_color = '#e4e4e4', fg_color = '#777777' },
        inactive_tab_hover = { bg_color = '#dddddd', fg_color = '#333333', italic = true },
        new_tab = { bg_color = '#eeeeee', fg_color = '#555555' },
        new_tab_hover = { bg_color = '#dddddd', fg_color = '#333333', italic = true },
    },
}

local is_light = read_theme_state()

local tmux_dark_theme = {
    status_bg = '#1f2335',
    status_fg = '#a9b1d6',
    pane_border = '#3b4261',
    active_border = '#0969da',
    message_bg = '#0969da',
    mode_bg = '#f0268f',
}

local tmux_light_theme = {
    status_bg = '#ffffff',
    status_fg = '#383a42',
    pane_border = '#e4e4e4',
    active_border = '#0969da',
    message_bg = '#0969da',
    mode_bg = '#e45649',
}

local function toggle_theme(window, _)
    is_light = not is_light
    write_theme_state(is_light)
    
    local new_opacity = is_light and 1.0 or 0.85
    local new_frame = is_light and light_window_frame or dark_window_frame
    local tmux_theme = is_light and tmux_light_theme or tmux_dark_theme
    
    local overrides = {
        window_background_opacity = new_opacity,
        window_frame = new_frame,
    }
    
    if is_light then
        overrides.colors = light_colors
    else
        overrides.color_scheme = dark_scheme
        overrides.colors = dark_colors
    end
    
    window:set_config_overrides(overrides)
    
    window:emit("theme-changed", is_light and "light" or "dark")
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
local home_dir = os.getenv("HOME") or "/home/" .. (os.getenv("USER") or "user")
local color_scheme_dirs = { home_dir .. "/.config/wezterm/colors/" }

local config = {
    check_for_updates = false,
    color_scheme_dirs = color_scheme_dirs,
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
    -- Keep the titlebar color consistent when unfocused to prevent resize issues
    inactive_titlebar_bg = '#191b28',
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
    { key = "y",      mods = "CTRL|SHIFT", action = wezterm.action_callback(toggle_theme) },

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
