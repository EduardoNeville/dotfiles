--- theme-sync.lua
--- Shared helper for reading the theme state file and applying
--- the correct colorscheme across Neovim.
---
--- State file: ~/.local/state/theme ("light" or "dark")
--- Written by wezterm's toggle_theme() on Ctrl+Shift+Y.
---
--- Uses a libuv fs_event watcher to react instantly when the
--- state file changes (no polling, no focus dependency), plus
--- a FocusGained fallback for safety.

local M = {}

local STATE_FILE = vim.fn.expand("~/.local/state/theme")
local fs_watch_handle = nil

--- Read the current theme from the state file.
--- @return string "light" or "dark"
function M.read_theme_state()
    local f = io.open(STATE_FILE, "r")
    if f then
        local state = f:read("*a"):gsub("%s+", "")
        f:close()
        if state == "light" then
            return "light"
        end
    end
    return "dark"
end

--- @return boolean true if currently in light mode
function M.is_light()
    return M.read_theme_state() == "light"
end

--- Apply the colorscheme corresponding to the current theme state.
--- Fires a User ThemeChanged event so other plugins (lualine, etc.)
--- can react.
function M.apply_colorscheme(is_light)
    if is_light then
        -- Catppuccin Latte (light mode)
        local ok, _ = pcall(function()
            vim.cmd.colorscheme("catppuccin-latte")
        end)
        if not ok then
            -- Fallback if catppuccin is not available
            vim.cmd.colorscheme("habamax")
        end
    else
        -- Synthweave (dark mode)
        local ok = pcall(function()
            local synthweave = require("synthweave")
            synthweave.setup({
                transparent = false,
                overrides = {
                    Identifier = { fg = "#f22f52" },
                },
            })
            synthweave.load()
        end)
        if not ok then
            -- Fallback if synthweave is not available
            vim.cmd.colorscheme("default")
        end
    end

    -- Fire event so other modules can react
    vim.api.nvim_exec_autocmds("User", { pattern = "ThemeChanged" })
end

--- Full sync: read state file, apply colorscheme, return whether we switched.
--- @return boolean switched
function M.sync()
    local was_light = vim.g.theme_is_light
    local now_light = M.is_light()

    if was_light == nil or was_light ~= now_light then
        vim.g.theme_is_light = now_light
        M.apply_colorscheme(now_light)
        return true
    end
    return false
end

--- Initial setup: read state, apply on first load, watch for changes.
function M.init()
    vim.g.theme_is_light = M.is_light()
    M.apply_colorscheme(vim.g.theme_is_light)

    -- Watch the state file for real-time changes (fires when Wezterm writes it)
    local ok, handle = pcall(vim.uv.new_fs_event)
    if ok and handle then
        fs_watch_handle = handle
        handle:start(STATE_FILE, {}, function(err, fname, events)
            if not err then
                M.sync()
            end
        end)

        -- Clean up the watcher on exit
        vim.api.nvim_create_autocmd("VimLeavePre", {
            callback = function()
                if fs_watch_handle and not fs_watch_handle:is_closing() then
                    fs_watch_handle:close()
                end
            end,
        })
    end

    -- FocusGained fallback (catches edge cases where fs_event might not fire)
    vim.api.nvim_create_autocmd("FocusGained", {
        pattern = "*",
        callback = M.sync,
    })

    -- Manual command for debugging / manual trigger
    vim.api.nvim_create_user_command("ThemeSync", M.sync, {})
end

return M
