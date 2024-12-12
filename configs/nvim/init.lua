local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end

vim.opt.rtp:prepend(lazypath)

-- <Leader> key is spacebar
vim.g.mapleader = " "
vim.g.maplocalleader = " "

require("lazy").setup("plugins", {
    change_detection = {
        notify = false,
    }
})

require('base')
require('keymaps')
require('colorscheme')
require('plugins')
require('plugins.telescope')
require('lsp-config.language-server')
