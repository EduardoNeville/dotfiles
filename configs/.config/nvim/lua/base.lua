local vim = vim 
vim.cmd('autocmd!')

-- File encoding
vim.scriptencoding = 'utf-8'
vim.opt.encoding = 'utf-8'
-- vim.opt.fileencofing = 'utf-8'
-- vim.opt.background_opacity = 0.92

-------------------------------------
-------------------------------------
-- Misc
-------------------------------------
-------------------------------------

--------
-- Line Info
--------
vim.wo.number = true
vim.wo.relativenumber = true

vim.opt.title = true
vim.opt.autoindent = true
vim.opt.hlsearch = true 
vim.opt.showcmd = true
vim.opt.cmdheight = 1
vim.opt.laststatus = 2
vim.opt.expandtab = true
vim.opt.scrolloff = 10
vim.opt.shell = 'zsh'
vim.opt.clipboard:append {'unnamedplus'}

------------
-- Tab info
------------

vim.opt.tabstop = 4
vim.opt.shiftwidth = 4

vim.opt.number = true
vim.opt.cursorline = true
vim.opt.showmode = true

------------
-- Cursor
------------

vim.opt.guicursor = 'n-v-c:block,i-ci-ve:ver25,r-cr:hor20,o:hor50,a:blinkwait700-blinkoff400-blinkon250-Cursor/lCursor,sm:block-blinkwait175-blinkoff150-blinkon175'
--highlight Cursor guifg=white guibg=black
--highlight iCursor guifg=white guibg=steelblue
--set guicursor=n-v-c:block-Cursor
--set guicursor+=i:ver100-iCursor
--set guicursor+=n-v-c:blinkon0
--set guicursor+=i:blinkwait10


------------
-- Nvim Tree
------------
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.opt.termguicolors = true

------------
-- Highlights
------------

vim.opt.termguicolors = true
-- vim.opt.winblend = 0
vim.opt.wildoptions = 'pum'
vim.opt.background = 'dark'

------------
-- Theme
------------

local fm = require 'fluoromachine'
fm.setup {
    glow = false,
    theme = 'retrowave',
    transparent = false,
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
            purple = '#9544f7',
        }
    end,

}

vim.cmd.colorscheme('fluoromachine')
