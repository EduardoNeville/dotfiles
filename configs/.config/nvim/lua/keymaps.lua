local vim = vim 
local set_keymaps =  vim.api.nvim_set_keymap


-- <Leader> key is spacebar 
vim.g.mapleader = ' '

------------------------------------------
------------------------------------------
-- Movements
------------------------------------------
------------------------------------------

--------
-- Move lines up (;) and down (n)
--------

-- Map ; to move the current line up in normal mode
vim.api.nvim_set_keymap('n', ';', ":m .-2<CR>==", { noremap = true, silent = true })
-- Map N to move the current line down in normal mode
vim.api.nvim_set_keymap('n', 'N', ":m .+1<CR>==", { noremap = true, silent = true })
-- Map ; to move the selected lines up in visual mode
vim.api.nvim_set_keymap('v', ';', ":'<,'>m '<-2<CR>gv=gv", { noremap = true, silent = true })
-- Map N to move the selected lines down in visual mode
vim.api.nvim_set_keymap('v', 'N', ":'>m '>+1<CR>gv=gv", { noremap = true, silent = true })

--------
-- Insert closing sign after {, (, [, "
--------

-- Map { to insert {} and move the cursor inside the braces in insert mode
set_keymaps ('i', '{', '{}<Esc>ha', { noremap = true, silent = true })
-- Map ( to insert () and move the cursor inside the parentheses in insert mode
set_keymaps ('i', '(', '()<Esc>ha', { noremap = true, silent = true })
-- Map [ to insert [] and move the cursor inside the brackets in insert mode
set_keymaps ('i', '[', '[]<Esc>ha', { noremap = true, silent = true })
-- Map " to insert "" and move the cursor inside the brackets in insert mode
set_keymaps ('i', '"', '""<Esc>ha', { noremap = true, silent = true })

-- selecting multiple non-contiguos lines
-- map the shortcut key to start selecting blocks of code
vim.api.nvim_set_keymap('v', '<leader>a', [[:<c-u>let @a=""]]..'\n', {silent=true})
vim.api.nvim_set_keymap('x', '<leader>a', [[:<c-u>let @a=""]]..'\n', {silent=true})

-- map the shortcut key to move to the next block of code
vim.api.nvim_set_keymap('n', '<leader>a', '/<\\_^i\\+><cr>n:call setpos(".", getpos("\'[")+1)<cr>', {silent=true})


------------------------------------------
------------------------------------------
-- Shortcuts to plugins 
------------------------------------------
------------------------------------------

-- NavBuddy
set_keymaps('n', '<leader>nav', ':Navbuddy<CR>', { noremap = true, silent = true })

-- Telescope keymaps
set_keymaps('n', '<leader>tel', ':Telescope<CR>', { noremap = true, silent = true })
--local builtin = require('telescope.builtin')
--vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
--vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
--vim.keymap.set('n', '<leader>fb', builtin.buffers, {})
--vim.keymap.set('n', '<leader>fh', builtin.help_tags, {})

-- Copilot change of key
vim.g.copilot_no_tab_map = true
-- Maps copilot accept to Control + J
vim.api.nvim_set_keymap("i", "<C-J>", 'copilot#Accept("<CR>")', { silent = true, expr = true })
-- Toggle NvimTree buffer with Tab while in a file
-- Maps copilot next to Control + K
vim.api.nvim_set_keymap("i", "<C-K>", 'copilot#Next()', { silent = true, expr = true })


-- Nvim Tree
vim.api.nvim_set_keymap('n', '<Tab>', ':NvimTreeToggle<CR>', { noremap = true, silent = true })


------------------------------------------
------------------------------------------
-- LSP keymaps
------------------------------------------
------------------------------------------

-- basic diagnostics/lsp jumping around
-- see `:help vim.diagnostic.*` for documentation on any of the below functions
vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float)
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev)
vim.keymap.set("n", "]d", vim.diagnostic.goto_next)
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist)

vim.keymap.set("n", "<leader>hov", vim.lsp.buf.hover)
vim.keymap.set("n", "<leader>def", vim.lsp.buf.definition)

