local set_api_keymaps = vim.api.nvim_set_keymap
local set_keymaps = vim.keymap.set

-- <Leader> key is spacebar
vim.g.mapleader = ' '

------------------------------------------
--- UnMapping
------------------------------------------

--vim.cmd('nnoremap s <Nop>')

------------------------------------------
--  Leap
--set_keymaps({'n', 'x', 'o'}, 'g',  '<Plug>(leap-forward)');
--set_keymaps({'n', 'x', 'o'}, 'G',  '<Plug>(leap-backward)');
--set_keymaps({'n', 'x', 'o'}, 'gs', '<Plug>(leap-from-window)');

------------------------------------------
--- Movements ----------------------------
------------------------------------------

--- Move lines up (k) and down (j) --------
--- Map <Option> k to move the current line up in normal mode
set_api_keymaps('n', '<M-k>', ":m .-2<CR>==", { noremap = true, silent = true })
set_api_keymaps('v', '<M-k>', ":'<,'>m '<-2<CR>gv=gv", { noremap = true, silent = true })
--- Map <Option> j to move the current line down in normal mode

set_api_keymaps('n', '<M-j>', ":m .+1<CR>==", { noremap = true, silent = true })
set_api_keymaps('v', '<M-j>', ":'>m '>+1<CR>gv=gv", { noremap = true, silent = true })

--- Insert closing sign after {, (, [, " --------
---
--- Map { to insert {} and move the cursor inside the braces in insert mode
set_api_keymaps('i', '{', '{}<Esc>ha', { noremap = true, silent = true })
--- Map ( to insert () and move the cursor inside the parentheses in insert mode
set_api_keymaps('i', '(', '()<Esc>ha', { noremap = true, silent = true })
--- Map [ to insert [] and move the cursor inside the brackets in insert mode
set_api_keymaps('i', '[', '[]<Esc>ha', { noremap = true, silent = true })
--- Map " to insert "" and move the cursor inside the brackets in insert mode
set_api_keymaps('i', '"', '""<Esc>ha', { noremap = true, silent = true })

--- Replace all instances of a highlighted word in block ----------
set_api_keymaps('v', '<leader>r', [["hy:%s/<C-r>h//gc<left><left><left>]], { noremap = true })

--- Remap pasted over text to void reg
set_api_keymaps('v', '<leader>p', "\"_dP", { noremap = true })

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
set_keymaps('n', '<leader>ff', builtin.fd, { noremap = true, silent = true })
set_keymaps('n', '<leader>fg', builtin.live_grep, {})
set_keymaps('n', '<leader>fb', builtin.buffers, {})
set_keymaps('n', '<leader>fh', builtin.help_tags, {})

---
--- Copilot ------------------------------
--- Copilot change of key
--- Maps copilot accept to Control + J
set_keymaps('i', '<C-Q>', 'copilot#Accept("\\<CR>")', {
  expr = true,
  replace_keycodes = false
})

vim.g.copilot_no_tab_map = true

--- ChatGPT --------------------------------
set_api_keymaps("n", "<leader>cg", ":ChatGPT<CR>", { noremap = true, silent = true })
set_api_keymaps("n", "<leader>ca", ":ChatGPTActAs<CR>", { noremap = true, silent = true })
set_api_keymaps("n", "<leader>ci", ":ChatGPTEditWithInstructions<CR>", { noremap = true, silent = true })


--- LSP ----------------------------------

--- basic diagnostics/lsp jumping around
--- see `:help vim.diagnostic.*` for documentation on any of the below functions
set_keymaps("n", "<leader>e", vim.diagnostic.open_float)
set_keymaps("n", "[d", vim.diagnostic.goto_prev)
set_keymaps("n", "]d", vim.diagnostic.goto_next)
set_keymaps("n", "<leader>q", vim.diagnostic.setloclist)
set_keymaps("n", "<leader>hov", vim.lsp.buf.hover)
set_keymaps("n", "<leader>def", vim.lsp.buf.definition)

-- New lsp commands
set_api_keymaps("n", "<leader>rn", "<cmd>lua vim.lsp.buf.format{async=true}<cr>", { noremap = true, silent = true })
set_api_keymaps("n", "<leader>la", "<cmd>lua vim.lsp.buf.code_action()<cr>", { noremap = true, silent = true })
-- set_api_keymaps("n", "<leader>lr", "<cmd>lua vim.lsp.buf.rename()<cr>", { noremap = true, silent = true })
set_api_keymaps("n", "<leader>lS", "<cmd>Telescope lsp_dynamic_workspace_symbols<cr>", { noremap = true, silent = true })

--- Debugger -----------------------------
