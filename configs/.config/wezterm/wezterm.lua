local wezterm = require("wezterm")
local colors = require('lua/rose-pine-moon').colors()
local window_frame = require('lua/rose-pine-moon').window_frame()

---------------------------------------------------------------
--- Config
---------------------------------------------------------------
local config = {
	-- font = wezterm.font("Cica"),
	-- font_size = 10.0,
        --
        -- Fira Code fonts
        -- https://github.com/tonsky/FiraCode
	font = wezterm.font('Fira Code', {weight="Regular", stretch='Normal', style=Normal}),
        font = wezterm.font_with_fallback {'Fira Code'},
        font_size = 15,
	-- cell_width = 1.1,
	-- line_height = 1.1,
	-- font_rules = {
	-- 	{
	-- 		italic = true,
	-- 		font = wezterm.font("Cica", { italic = true }),
	-- 	},
	-- 	{
	-- 		italic = true,
	-- 		intensity = "Bold",
	-- 		font = wezterm.font("Cica", { weight = "Bold", italic = true }),
	-- 	},
	-- },
	check_for_updates = false,
	use_ime = true,

        -- Default colours
        --color_scheme = "Catppuccin Macchiato",
	--color_scheme_dirs = { os.getenv("HOME") .. "/.config/wezterm/colors/" },
	colors = colors,
	--window_frame = window_frame,

}

return config
