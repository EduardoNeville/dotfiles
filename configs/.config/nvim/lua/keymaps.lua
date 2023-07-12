local vim = vim
local set_api_keymaps =  vim.api.nvim_set_keymap
local set_keymaps = vim.keymap.set

-- <Leader> key is spacebar 
vim.g.mapleader = ' '

------------------------------------------
--- Movements ----------------------------
------------------------------------------


--- Move lines up (k) and down (j) --------

--- Map <leader> k to move the current line up in normal mode
set_api_keymaps('n', '<leader>k', ":m .-2<CR>==", { noremap = true, silent = true })
set_api_keymaps('v', '<leader>k', ":'<,'>m '<-2<CR>gv=gv", { noremap = true, silent = true })

--- Map <leader> j to move the current line down in normal mode

set_api_keymaps('n', '<leader>j', ":m .+1<CR>==", { noremap = true, silent = true })

set_api_keymaps('v', '<leader>j', ":'>m '>+1<CR>gv=gv", { noremap = true, silent = true })

--- Insert closing sign after {, (, [, " --------

--- Map { to insert {} and move the cursor inside the braces in insert mode
set_api_keymaps('i', '{', '{}<Esc>ha', { noremap = true, silent = true })
--- Map ( to insert () and move the cursor inside the parentheses in insert mode
set_api_keymaps('i', '(', '()<Esc>ha', { noremap = true, silent = true })
--- Map [ to insert [] and move the cursor inside the brackets in insert mode
set_api_keymaps('i', '[', '[]<Esc>ha', { noremap = true, silent = true })
--- Map " to insert "" and move the cursor inside the brackets in insert mode
set_api_keymaps('i', '"', '""<Esc>ha', { noremap = true, silent = true })

--- Replace all instances of a highlighted word in block ---------- 
set_api_keymaps('v', '<leader>r', [["hy:%s/<C-r>h//gc<left><left><left>]], {noremap = true})

-- selecting multiple non-contiguos lines
-- map the shortcut key to start selecting blocks of code
set_api_keymaps('v', '<leader>a', [[:<c-u>let @a=""]]..'\n', {silent=true})
set_api_keymaps('x', '<leader>a', [[:<c-u>let @a=""]]..'\n', {silent=true})

-- map the shortcut key to move to the next block of code
set_api_keymaps('n', '<leader>a', '/<\\_^i\\+><cr>n:call setpos(".", getpos("\'[")+1)<cr>', {silent=true})


------------------------------------------
--- Shortcuts to plugins -----------------
------------------------------------------

--- NvimTreeToggle -----------------------
set_api_keymaps('n', '<leader>nt', ':NvimTreeToggle<CR>', { noremap = true, silent = true })
--- NnnPicker ----------------------------
set_api_keymaps('n', '<leader>nn', ':NnnPicker<CR>', { noremap = true, silent = true })
--- Navbuddy -----------------------------
set_api_keymaps('n', '<leader>nav', ':Navbuddy<CR>', { noremap = true, silent = true })

--- Tmux ---------------------------------
--- < Control and direction > ------------
set_api_keymaps('n', '<C-h>', ':TmuxNavigateLeft<CR>', { noremap = true, silent = true })
set_api_keymaps('n', '<C-j>', ':TmuxNavigateDown<CR>', { noremap = true, silent = true })
set_api_keymaps('n', '<C-k>', ':TmuxNavigateUp<CR>', { noremap = true, silent = true })
set_api_keymaps('n', '<C-l>', ':TmuxNavigateRight<CR>', { noremap = true, silent = true })

--- Telescope ---------------------------- 
set_api_keymaps('n', '<leader>tel', ':Telescope<CR>', { noremap = true, silent = true })
local builtin = require('telescope.builtin')
set_keymaps('n', '<leader>ff', builtin.find_files, {})
--vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
--vim.keymap.set('n', '<leader>fb', builtin.buffers, {})
--vim.keymap.set('n', '<leader>fh', builtin.help_tags, {})

--- Copilot ------------------------------
--- Copilot change of key
--- Maps copilot accept to Control + J
vim.api.nvim_set_keymap('i', '<C-J>', [[<Cmd>lua require('copilot').Accept("\<CR>")<CR>]], {silent = true, expr = true, noremap = true})
--- Maps copilot next to Control + K
set_api_keymaps("i", "<C-K>", 'copilot#Next()', { silent = true, expr = true })
vim.g.copilot_no_tab_map = true

----
--- ChatGPT --------------------------------
---
set_api_keymaps("n","<leader>cg",":ChatGPT<CR>", { noremap = true, silent = true })

--- LSP ---------------------------------- 

--- basic diagnostics/lsp jumping around
--- see `:help vim.diagnostic.*` for documentation on any of the below functions
set_keymaps("n", "<leader>e", vim.diagnostic.open_float)
set_keymaps("n", "[d", vim.diagnostic.goto_prev)
set_keymaps("n", "]d", vim.diagnostic.goto_next)
set_keymaps("n", "<leader>q", vim.diagnostic.setloclist)
set_keymaps("n", "<leader>hov", vim.lsp.buf.hover)
set_keymaps("n", "<leader>def", vim.lsp.buf.definition)

--- Debugger -----------------------------

