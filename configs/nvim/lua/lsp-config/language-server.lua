local lspconfig       = require("lspconfig")
local mason_lspconfig = require("mason-lspconfig")
local navbuddy = require("nvim-navbuddy")

local capabilities = require("cmp_nvim_lsp").default_capabilities()

local servers = {
  lua_ls        = {},
  rust_analyzer = {},
  clangd        = {},
  eslint        = {},
  pyright       = {},
  ruff          = {},
}

-- install all of them
mason_lspconfig.setup {
  ensure_installed = vim.tbl_keys(servers),

  -- NEW api (v2.0+)
  handlers = {
    function(server_name)         -- default handler called for each server
      lspconfig[server_name].setup {
        capabilities = capabilities,
        settings     = servers[server_name],
        on_attach    = function (client, bufnr)
            navbuddy.attach(client, bufnr)
        end
      }
    end,
  },
}
