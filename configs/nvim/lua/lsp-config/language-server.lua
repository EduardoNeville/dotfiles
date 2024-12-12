-- lsp-config.lua

-- Learn the keybindings, see :help lsp-zero-keybindings
-- Learn to configure LSP servers, see :help lsp-zero-api-showcase
local lsp = require('lsp-zero')

lsp.preset('recommended')

-- (Optional) Configure lua language server for neovim
lsp.nvim_workspace()

-- using navbuddy for navigation
local navbuddy = require("nvim-navbuddy")

-- Attach navbuddy to LSP
lsp.on_attach(
    function(client, bufnr)
        navbuddy.attach(client, bufnr)
    end
)

lsp.setup()

local rt = require("rust-tools")

rt.setup({
  server = {
    on_attach = function(_, bufnr)
      -- Hover actions
      vim.keymap.set("n", "<C-space>", rt.hover_actions.hover_actions, { buffer = bufnr })
      -- Code action groups
      vim.keymap.set("n", "<Leader>a", rt.code_action_group.code_action_group, { buffer = bufnr })
      navbuddy.attach(_, bufnr)
    end,
  },
})
