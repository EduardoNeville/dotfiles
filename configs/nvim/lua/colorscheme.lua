--- Colorscheme config ----------------------------------------

--- Setup for fluoromachine
local fm = require 'fluoromachine'
fm.setup {
    glow = false,
    theme = 'retrowave',
    transparent = "full",
    overrides = {
        ['@type'] = { italic = true, bold = false },
        ['@function'] = { italic = false, bold = false },
        ['@comment'] = { italic = true , bold = false},
        ['@keyword'] = { italic = false , bold= false},
        ['@constant'] = { italic = false, bold = false },
        ['@variable'] = { italic = true , bold= false},
        ['@field'] = { italic = true , bold= false},
        ['@parameter'] = { italic = true , bold= false},
    },
    colors = function(_, d)
        return {
            bg = '#190920',
            alt_bg = d('#190920', 20),
            cyan = '#49eaff',
            red = '#ff1e34',
            yellow = '#ffe756',
            comment = '#57ff00',
            orange = '#f38e21',
            pink = '#ffadff',
            purple = '#9544f7'}
        end
}

--- Setup for synthweave
local sw = require 'synthweave'
sw.setup {
    config = function()
        local synthweave = require("synthweave")
        synthweave.setup({
            transparent = false,
            overrides = {
                -- override any group
                Identifier = {
                    fg = "#f22f52",
                },
            },
            palette = {
                -- override palette colors, take a peek at synthweave/palette.lua
                bg0 = "#040404",
                bg1 = "#55a8fb",
                bg2 = "#55a8fb",
                bg3 = "#55a8fb",
            },
        })
        synthweave.load()
    end,
}

--- Setup for blue
vim.cmd.colorscheme('synthweave')
vim.cmd [[hi Comment guifg=#7ceb9a]]
vim.cmd [[hi LineNr guifg=#7ceb9a]]
--- Minimap
vim.cmd [[hi MinimapCursor guifg=#00fbfd]]
vim.cmd [[hi MinimapRange guifg=#55a8fb]]



