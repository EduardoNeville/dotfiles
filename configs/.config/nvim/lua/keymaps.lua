local set_keymaps =  vim.api.nvim_set_keymap

-- Map leader to space
vim.g.mapleader = ' '

-- Map K to move the current line up in normal mode
vim.api.nvim_set_keymap('n', 'K', ":m .-2<CR>==", { noremap = true, silent = true })
-- Map J to move the current line down in normal mode
vim.api.nvim_set_keymap('n', 'J', ":m .+1<CR>==", { noremap = true, silent = true })
-- Map K to move the selected lines up in visual mode
vim.api.nvim_set_keymap('v', 'K', ":'<,'>m '<-2<CR>gv=gv", { noremap = true, silent = true })
-- Map J to move the selected lines down in visual mode
vim.api.nvim_set_keymap('v', 'J', ":'>m '>+1<CR>gv=gv", { noremap = true, silent = true })

-- Map { to insert {} and move the cursor inside the braces in insert mode
set_keymaps ('i', '{', '{}<Esc>ha', { noremap = true, silent = true })
-- Map ( to insert () and move the cursor inside the parentheses in insert mode
set_keymaps ('i', '(', '()<Esc>ha', { noremap = true, silent = true })
-- Map [ to insert [] and move the cursor inside the brackets in insert mode
set_keymaps ('i', '[', '[]<Esc>ha', { noremap = true, silent = true })
-- Map " to insert "" and move the cursor inside the brackets in insert mode
set_keymaps ('i', '"', '""<Esc>ha', { noremap = true, silent = true })

-- Telescope keymaps
--local builtin = require('telescope.builtin')
--vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
--vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
--vim.keymap.set('n', '<leader>fb', builtin.buffers, {})
--vim.keymap.set('n', '<leader>fh', builtin.help_tags, {})

-- Copilot change of key
vim.g.copilot_no_tab_map = true
-- Maps copilot accept to Control + J
vim.api.nvim_set_keymap("i", "<C-J>", 'copilot#Accept("<CR>")', { silent = true, expr = true })
-- Maps copilot next to Control + K
vim.api.nvim_set_keymap("i", "<C-K>", 'copilot#Next()', { silent = true, expr = true })

--------
-- Nvim Tree
--------
-- Toggle NvimTree buffer with Tab while in a file
vim.api.nvim_set_keymap('n', '<Tab>', ':NvimTreeToggle<CR>', { noremap = true, silent = true })



-- Selecting multiple non-contiguos lines

-- Map the shortcut key to start selecting blocks of code
vim.api.nvim_set_keymap('v', '<leader>a', [[:<C-u>let @a=""]]..'\n', {silent=true})
vim.api.nvim_set_keymap('x', '<leader>a', [[:<C-u>let @a=""]]..'\n', {silent=true})

-- Map the shortcut key to move to the next block of code
vim.api.nvim_set_keymap('n', '<leader>a', '/<\\_^I\\+><cr>n:call setpos(".", getpos("\'[")+1)<cr>', {silent=true})


-- Basic Diagnostics/LSP jumping around
-- See `:help vim.diagnostic.*` for documentation on any of the below functions
vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float)
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev)
vim.keymap.set("n", "]d", vim.diagnostic.goto_next)
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist)

-- Server specific LSP keymaps
-- Called by the `on_attach` in the lspconfig setup
local server_maps = function(bufopts)
  vim.keymap.set("n", "gD", vim.lsp.buf.declaration, bufopts)
  vim.keymap.set("n", "gd", vim.lsp.buf.definition, bufopts)
  vim.keymap.set("n", "<leader>gd", vim.lsp.buf.hover, bufopts)
  vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, bufopts)
  vim.keymap.set("n", "gr", vim.lsp.buf.references, bufopts)
  vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, bufopts)
  vim.keymap.set("n", "<leader>fo", function()
    vim.lsp.buf.format({ async = true })
  end, bufopts)
end

