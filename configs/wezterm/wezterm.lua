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

local dark_scheme = "Night Owl (Gogh)"
local light_scheme = "Night Owlish Light"

local dark_window_frame = {
    active_titlebar_bg = '#011627',
    inactive_titlebar_bg = '#011627',
}

local dark_colors = {
    background = '#011627',
    foreground = '#d6deeb',
    cursor_bg = '#80a4c2',
    cursor_border = '#80a4c2',
    selection_bg = '#1d3b53',
    selection_fg = '#d6deeb',
    ansi = {
        '#011627', -- black
        '#ef5350', -- red
        '#22da6e', -- green
        '#c5e478', -- yellow
        '#82aaff', -- blue
        '#c792ea', -- magenta
        '#21c7a8', -- cyan
        '#d6deeb', -- white
    },
    brights = {
        '#575656', -- bright black
        '#ef5350', -- bright red
        '#22da6e', -- bright green
        '#ffeb95', -- bright yellow
        '#82aaff', -- bright blue
        '#c792ea', -- bright magenta
        '#7fdbca', -- bright cyan
        '#ffffff', -- bright white
    },
}

local light_window_frame = {
    active_titlebar_bg = '#fbfbfb',
    inactive_titlebar_bg = '#fbfbfb',
}

local light_colors = {
    background = '#fbfbfb',
    foreground = '#403f53',
    cursor_bg = '#90a7b2',
    cursor_border = '#90a7b2',
    selection_bg = '#e0e0e0',
    selection_fg = '#403f53',
    ansi = {
        '#403f53', -- black
        '#de3d3b', -- red
        '#08916a', -- green
        '#e0af02', -- yellow
        '#288ed7', -- blue
        '#d6438a', -- magenta
        '#2aa298', -- cyan
        '#f0f0f0', -- white
    },
    brights = {
        '#403f53', -- bright black
        '#de3d3b', -- bright red
        '#08916a', -- bright green
        '#daaa01', -- bright yellow
        '#288ed7', -- bright blue
        '#d6438a', -- bright magenta
        '#2aa298', -- bright cyan
        '#f0f0f0', -- bright white
    },
    indexed = { [16] = '#e0af02', [17] = '#403f53' },
    scrollbar_thumb = '#c0c0c0',
    split = '#e0e0e0',
    tab_bar = {
        active_tab = { bg_color = '#fbfbfb', fg_color = '#403f53' },
        inactive_tab = { bg_color = '#e0e0e0', fg_color = '#989fb1' },
        inactive_tab_hover = { bg_color = '#d0d0d0', fg_color = '#403f53', italic = true },
        new_tab = { bg_color = '#ebebeb', fg_color = '#787b8a' },
        new_tab_hover = { bg_color = '#d0d0d0', fg_color = '#403f53', italic = true },
    },
}

local is_light = read_theme_state()

local tmux_dark_theme = {
    status_bg = '#011627',
    status_fg = '#d6deeb',
    pane_border = '#1d3b53',
    active_border = '#82aaff',
    message_bg = '#82aaff',
    mode_bg = '#c792ea',
}

local tmux_light_theme = {
    status_bg = '#fbfbfb',
    status_fg = '#403f53',
    pane_border = '#e0e0e0',
    active_border = '#288ed7',
    message_bg = '#288ed7',
    mode_bg = '#d6438a',
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

    if is_light then
        window:emit("passthrough", "\x1b]10;#fbfbfb\x1b\\")
        window:emit("passthrough", "\x1b]11;#403f53\x1b\\")
    else
        window:emit("passthrough", "\x1b]10;#d6deeb\x1b\\")
        window:emit("passthrough", "\x1b]11;#011627\x1b\\")
    end
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
    active_titlebar_bg = '#011627',
    inactive_titlebar_bg = '#011627',
}

config.colors = {
    tab_bar = {
        -- The active tab is the one that has focus in the window
        active_tab = {
            bg_color = "#011627",
            fg_color = "#82aaff",
            intensity = 'Normal',
            underline = 'None',
            italic = false,
            strikethrough = false,
        },

        inactive_tab = {
            bg_color = "#0b2942",
            fg_color = "#565f89",
        },

        inactive_tab_hover = {
            bg_color = '#0b2942',
            fg_color = '#82aaff',
            italic = true,
        },

        new_tab = {
            bg_color = '#82aaff',
            fg_color = '#011627',
        },

        new_tab_hover = {
            bg_color = '#0b2942',
            fg_color = '#82aaff',
            italic = true,
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
