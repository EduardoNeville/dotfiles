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

-- ── Light Mode Colors (Catppuccin Latte-inspired) ──────────
-- Background: off-white #FAFAFA, Foreground: near-black #1A1A2E

local light_window_frame = {
    active_titlebar_bg = '#FAFAFA',
    inactive_titlebar_bg = '#FAFAFA',
}

local light_colors = {
    background = '#FAFAFA',
    foreground = '#1A1A2E',
    cursor_bg = '#1E66F5',
    cursor_border = '#1E66F5',
    selection_bg = '#BEE3F8',
    selection_fg = '#1A1A2E',
    ansi = {
        '#2D3748', -- black (dark gray)
        '#D20F39', -- red
        '#40A02B', -- green
        '#DF8E1D', -- yellow
        '#1E66F5', -- blue
        '#EA76CB', -- magenta (pink)
        '#179299', -- cyan (teal)
        '#F5F5F9', -- white (near-white)
    },
    brights = {
        '#4A5568', -- bright black
        '#D20F39', -- bright red
        '#40A02B', -- bright green
        '#DF8E1D', -- bright yellow
        '#1E66F5', -- bright blue
        '#EA76CB', -- bright magenta
        '#179299', -- bright cyan
        '#FFFFFF', -- bright white
    },
    indexed = { [16] = '#DF8E1D', [17] = '#1A1A2E' },
    scrollbar_thumb = '#E6E9EF',
    split = '#E6E9EF',
    tab_bar = {
        active_tab = { bg_color = '#FAFAFA', fg_color = '#1A1A2E' },
        inactive_tab = { bg_color = '#E6E9EF', fg_color = '#9CA0B0' },
        inactive_tab_hover = { bg_color = '#D0D5DD', fg_color = '#1A1A2E', italic = true },
        new_tab = { bg_color = '#E6E9EF', fg_color = '#6C6F85' },
        new_tab_hover = { bg_color = '#D0D5DD', fg_color = '#1A1A2E', italic = true },
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
    status_bg = '#FAFAFA',
    status_fg = '#1A1A2E',
    pane_border = '#E6E9EF',
    active_border = '#1E66F5',
    message_bg = '#1E66F5',
    mode_bg = '#8839EF',
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

    -- OSC 10 = text foreground color, OSC 11 = text background color
    -- These are forwarded through tmux passthrough to update programs
    -- that query terminal colors.
    if is_light then
        window:emit("passthrough", "\x1b]10;#1A1A2E\x1b\\")
        window:emit("passthrough", "\x1b]11;#FAFAFA\x1b\\")
    else
        window:emit("passthrough", "\x1b]10;#d6deeb\x1b\\")
        window:emit("passthrough", "\x1b]11;#011627\x1b\\")
    end

    -- Propagate theme state to local tmux and remote SSH hosts.
    -- Calls propagate_state.sh from the dotfiles repo (~/dotfiles is
    -- always cloned on every machine so this path is always valid).
    -- propagate_state.sh:
    --   1. Writes state locally
    --   2. Syncs local tmux if inside a tmux session
    --   3. SSHes to each host in ~/.config/theme/remote-hosts and
    --      writes state there + syncs their tmux
    wezterm.run_child_process({
        "bash", "-c",
        "~/dotfiles/configs/theme/scripts/propagate_state.sh " .. (is_light and "light" or "dark")
    })
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

--- Window Frame & Tab Bar (respect theme state)
if is_light then
    config.window_background_opacity = 1.0
    config.window_frame = light_window_frame
    config.colors = {
        tab_bar = {
            active_tab = {
                bg_color = "#FAFAFA",
                fg_color = "#1A1A2E",
                intensity = 'Normal',
                underline = 'None',
                italic = false,
                strikethrough = false,
            },
            inactive_tab = {
                bg_color = "#E6E9EF",
                fg_color = "#9CA0B0",
            },
            inactive_tab_hover = {
                bg_color = '#D0D5DD',
                fg_color = '#1A1A2E',
                italic = true,
            },
            new_tab = {
                bg_color = '#E6E9EF',
                fg_color = '#6C6F85',
            },
            new_tab_hover = {
                bg_color = '#D0D5DD',
                fg_color = '#1A1A2E',
                italic = true,
            },
        },
    }
else
    config.window_frame = {
        active_titlebar_bg = '#011627',
        inactive_titlebar_bg = '#011627',
    }
    config.colors = {
        tab_bar = {
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
end

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

config.window_decorations = "RESIZE"

return config
