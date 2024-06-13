-- Ensure which-key is installed and loaded
require("which-key").setup {}

-- <Leader> key is spacebar
vim.g.mapleader = ' '
-- Centralized key mappings
local mappings = {
    -- Flash plugin configuration
    s = { function() require("flash").jump() end, "Flash" },

    -- Movements
    ["<M-k>"] = { ":m .-2<CR>==", "Move line up", noremap = true, silent = true },
    ["<M-j>"] = { ":m .+1<CR>==", "Move line down", noremap = true, silent = true },
    -- Insert closing sign after {, (, [, "
    i = {
        ["{"] = { '{}<Esc>ha', "Insert {}", noremap = true, silent = true },
        ["("] = { '()<Esc>ha', "Insert ()", noremap = true, silent = true },
        ["["] = { '[]<Esc>ha', "Insert []", noremap = true, silent = true },
        ['"'] = { '""<Esc>ha', 'Insert ""', noremap = true, silent = true },

        -- Copilot
        ["<C-Q>"] = { 'copilot#Accept("\\<CR>")', "Copilot Accept", expr = true, replace_keycodes = false },
    },
    -- Visual mode mappings
    v = {
        ["<M-k>"] = { ":'<,'>m '<-2<CR>gv=gv", "Move selection up", noremap = true, silent = true },
        ["<M-j>"] = { ":'>m '>+1<CR>gv=gv", "Move selection down", noremap = true, silent = true },
        ["<leader>r"] = { [["hy:%s/<C-r>h//gc<left><left><left>]], "Replace highlighted word", noremap = true },
        ["<leader>p"] = { "\"_dP", "Paste over text", noremap = true },
    },
    
    -- Shortcuts to plugins
    ["<leader>nn"] = { ":NnnPicker<CR>", "NnnPicker", noremap = true, silent = true },
    ["<leader>nav"] = { ":Navbuddy<CR>", "Navbuddy", noremap = true, silent = true },
    ["<leader>tel"] = { ":Telescope<CR>", "Telescope", noremap = true, silent = true },
    ["<leader>ff"] = { require('telescope.builtin').fd, "Find files", noremap = true, silent = true },
    ["<leader>fg"] = { require('telescope.builtin').live_grep, "Live grep" },
    ["<leader>fb"] = { require('telescope.builtin').buffers, "Buffers" },
    ["<leader>fh"] = { require('telescope.builtin').help_tags, "Help tags" },
    ["<leader>cg"] = { ":ChatGPT<CR>", "ChatGPT", noremap = true, silent = true },
    ["<leader>ca"] = { ":ChatGPTActAs<CR>", "ChatGPT Act As", noremap = true, silent = true },
    ["<leader>ci"] = { ":ChatGPTEditWithInstructions<CR>", "ChatGPT Edit", noremap = true, silent = true },

    -- LSP
    ["<leader>e"] = { vim.diagnostic.open_float, "Open diagnostic float" },
    ["[d"] = { vim.diagnostic.goto_prev, "Go to previous diagnostic" },
    ["]d"] = { vim.diagnostic.goto_next, "Go to next diagnostic" },
    ["<leader>q"] = { vim.diagnostic.setloclist, "Set location list" },
    ["<leader>hov"] = { vim.lsp.buf.hover, "Hover" },
    ["<leader>def"] = { vim.lsp.buf.definition, "Go to definition" },
    ["<leader>rn"] = { "<cmd>lua vim.lsp.buf.format{async=true}<cr>", "Format code", noremap = true, silent = true },
    ["<leader>la"] = { "<cmd>lua vim.lsp.buf.code_action()<cr>", "Code action", noremap = true, silent = true },
    ["<leader>lS"] = { "<cmd>Telescope lsp_dynamic_workspace_symbols<cr>", "Workspace symbols", noremap = true, silent = true },
}

-- Register all mappings with which-key
require("which-key").register(mappings,   { mode = "n" })
require("which-key").register(mappings.i, { mode = "i", buffer = nil, silent = true, nowait = false })
require("which-key").register(mappings.v, { mode = "v" })

