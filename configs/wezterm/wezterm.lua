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
local light_scheme = "catppuccin-latte"

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

-- ── Light Mode Frame ──────────────────────────────────────

local light_window_frame = {
    active_titlebar_bg = '#EFF1F5',
    inactive_titlebar_bg = '#EFF1F5',
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
    status_bg = '#EFF1F5',
    status_fg = '#4C4F69',
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
        overrides.color_scheme = light_scheme
        -- Text must be black in light mode (catppuccin-latte's default
        -- foreground #4C4F69 renders as hard-to-read gray).
        overrides.colors = { foreground = "#000000" }
    else
        overrides.color_scheme = dark_scheme
        overrides.colors = dark_colors
    end

    window:set_config_overrides(overrides)

    -- window:emit() does not exist in wezterm's Lua API (see wezterm.emit in
    -- https://wezterm.org/config/lua/wezterm/emit.html); the Window object has
    -- no emit method. wezterm.emit() dispatches to handlers registered via
    -- wezterm.on(). No 'theme-changed' handler is registered, so this is a
    -- harmless no-op that keeps the toggle working.
    wezterm.emit("theme-changed", is_light and "light" or "dark")

    -- No 'passthrough' event exists in wezterm and window:emit() is not an API,
    -- so the former OSC 10/11 passthrough block was dead code. It is not needed:
    -- the palette is applied via set_config_overrides above, and wezterm answers
    -- OSC 10/11 color queries automatically from its current palette.
    -- Cross-host/tmux theme sync is handled below by propagate_state.sh.

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
-- Pi integration notes (https://pi.dev/docs/latest/terminal-setup#wezterm)
--
-- 1. WezTerm "works out of the box for Shift+Enter via xterm
--    modifyOtherKeys", so we deliberately do NOT set
--    `enable_kitty_keyboard = true`. It is purely optional in the pi docs;
--    leaving it off avoids re-encoding key events as CSI-u and keeps the
--    xterm modifyOtherKeys path that already satisfies pi.
--
-- 2. The macOS `Option+Enter` fullscreen-override binding is macOS-only
--    and does not apply here (Debian/Linux).
--
-- 3. If you ever see a pasted newline render as the literal text
--    `[106;5u` (Kitty/CSI-u encoding of Ctrl+J), that is NOT this config.
--    It is the tmux 3.5a paste bug with `extended-keys`/`extended-keys-
--    format csi-u` (which the pi tmux docs recommend and tmux.conf has):
--    tmux re-interprets the pasted LF byte as a Ctrl+J key and re-emits it
--    as ESC[106;5u. Upgrade tmux to >= 3.5b (fix: "pasting no longer
--    interprets input as key sequences") and `tmux kill-server` to apply.
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
    config.color_scheme = light_scheme
    config.window_frame = light_window_frame
    config.colors = {
        foreground = "#000000", -- black text in light mode (see toggle_theme)
        tab_bar = {
            active_tab = {
                bg_color = "#EFF1F5",
                fg_color = "#1E66F5",
                intensity = 'Normal',
                underline = 'None',
                italic = false,
                strikethrough = false,
            },
            inactive_tab = {
                bg_color = "#E6E9EF",
                fg_color = "#000000",
            },
            inactive_tab_hover = {
                bg_color = '#CCD0DA',
                fg_color = '#000000',
                italic = true,
            },
            new_tab = {
                bg_color = '#E6E9EF',
                fg_color = '#000000',
            },
            new_tab_hover = {
                bg_color = '#CCD0DA',
                fg_color = '#000000',
                italic = true,
            },
        },
    }
else
    config.color_scheme = dark_scheme
    config.window_frame = {
        active_titlebar_bg = '#011627',
        inactive_titlebar_bg = '#011627',
    }
    -- Apply the SAME palette as toggle_theme()'s dark_colors so that a cold
    -- dark start matches the toggled-to-dark appearance (background, cursor,
    -- selection, ANSI). Without this, startup relied on the built-in Gogh
    -- scheme defaults, which differed from the toggle's dark_colors override.
    config.colors = {
        background = dark_colors.background,
        foreground = dark_colors.foreground,
        cursor_bg = dark_colors.cursor_bg,
        cursor_border = dark_colors.cursor_border,
        selection_bg = dark_colors.selection_bg,
        selection_fg = dark_colors.selection_fg,
        ansi = dark_colors.ansi,
        brights = dark_colors.brights,
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
