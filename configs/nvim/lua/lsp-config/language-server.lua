local lspconfig = require("lspconfig")
local navbuddy  = require("nvim-navbuddy")

local capabilities = require("cmp_nvim_lsp").default_capabilities()

-- Common on_attach function for all servers
local on_attach = function(client, bufnr)
  navbuddy.attach(client, bufnr)
end

-- Define servers to setup
local servers = {
  lua_ls = {
    settings = {
      Lua = {
        diagnostics = {
          globals = { "vim" }
        }
      }
    }
  },
  rust_analyzer = {},
  clangd = {},
  eslint = {},
  pyright = {},
  ruff = {},
}

-- Setup each server manually
for server, config in pairs(servers) do
  lspconfig[server].setup(vim.tbl_deep_extend("force", {
    capabilities = capabilities,
    on_attach = on_attach,
  }, config))
end
