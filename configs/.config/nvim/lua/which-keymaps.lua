local wk = require("which-key")
local vim = vim
local set_keymaps =  vim.api.nvim_set_keymap

-- <Leader> key is spacebar 
vim.g.mapleader = ' '

wk.register(mappings, opts)
{
  mode = "n", -- NORMAL mode
  -- prefix: use "<leader>f" for example for mapping everything related to finding files
  -- the prefix is prepended to every mapping part of `mappings`
  prefix = ' ',
  buffer = nil, -- Global mappings. Specify a buffer number for buffer local mappings
  silent = true, -- use `silent` when creating keymaps
  noremap = true, -- use `noremap` when creating keymaps
  nowait = false, -- use `nowait` when creating keymaps
  expr = false, -- use `expr` when creating keymaps
}

wk.register({

})

