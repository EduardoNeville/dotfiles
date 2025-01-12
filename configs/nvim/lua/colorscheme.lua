--- Colorscheme config ----------------------------------------

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
                -- override palette colors,
                -- take a peek at synthweave/palette.lua
            },
        })
        synthweave.load()
    end,
}

--- Setup for blue
vim.cmd.colorscheme('synthweave')
vim.cmd.highlight('Comment guifg=#7ceb9a')
vim.cmd.highlight('LineNr guifg=#7ceb9a')


