vim.cmd('autocmd!')

vim.scriptencoding = 'utf-8'
vim.opt.encoding = 'utf-8'
-- vim.opt.fileencofing = 'utf-8'
-- vim.opt.background_opacity = 0.92

vim.wo.number = true
--vim.wo.relativenumber = true

vim.opt.title = true
vim.opt.autoindent = true
vim.opt.hlsearch = true 
vim.opt.showcmd = true
vim.opt.cmdheight = 1
vim.opt.laststatus = 2
vim.opt.expandtab = true
vim.opt.scrolloff = 10
vim.opt.shell = 'zsh'

vim.opt.tabstop = 4
vim.opt.shiftwidth = 4

-- My commands
vim.opt.number = true
vim.opt.cursorline = true
vim.opt.showmode = true

-- Cursor
vim.opt.guicursor = 'n-v-c:block,i-ci-ve:ver25,r-cr:hor20,o:hor50,a:blinkwait700-blinkoff400-blinkon250-Cursor/lCursor,sm:block-blinkwait175-blinkoff150-blinkon175'
--highlight Cursor guifg=white guibg=black
--highlight iCursor guifg=white guibg=steelblue
--set guicursor=n-v-c:block-Cursor
--set guicursor+=i:ver100-iCursor
--set guicursor+=n-v-c:blinkon0
--set guicursor+=i:blinkwait10


vim.opt.clipboard:append {'unnamedplus'}

------------
-- Nvim Tree
------------
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.opt.termguicolors = true

