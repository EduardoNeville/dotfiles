local capabilities = require("cmp_nvim_lsp").default_capabilities()

-- Common on_attach function for all servers
local on_attach = function(client, bufnr)
  require("nvim-navbuddy").attach(client, bufnr)
end

-- Configure custom LSP servers
vim.lsp.config('lua_ls', {
  capabilities = capabilities,
  on_attach = on_attach,
  settings = {
    Lua = {
      diagnostics = {
        globals = { "vim" },
      },
      workspace = {
        library = {
          vim.env.VIMRUNTIME,
        },
      },
    },
  },
})

vim.lsp.config('rust_analyzer', {
  capabilities = capabilities,
  on_attach = on_attach,
  settings = {
    ["rust-analyzer"] = {
      checkOnSave = {
        command = "clippy",
      },
      diagnostics = {
        enable = true,
      },
    },
  },
})

vim.lsp.config('ts_ls', {
  capabilities = capabilities,
  on_attach = on_attach,
  settings = {
    typescript = {
      inlayHints = {
        includeInlayParameterNameHints = "all",
        includeInlayParameterNameHintsWhenArgumentMatchesName = false,
        includeInlayFunctionParameterTypeHints = true,
        includeInlayVariableTypeHints = true,
        includeInlayPropertyDeclarationTypeHints = true,
        includeInlayFunctionLikeReturnTypeHints = true,
        includeInlayEnumMemberValueHints = true,
      },
    },
    javascript = {
      inlayHints = {
        includeInlayParameterNameHints = "all",
        includeInlayParameterNameHintsWhenArgumentMatchesName = false,
        includeInlayFunctionParameterTypeHints = true,
        includeInlayVariableTypeHints = true,
        includeInlayPropertyDeclarationTypeHints = true,
        includeInlayFunctionLikeReturnTypeHints = true,
        includeInlayEnumMemberValueHints = true,
      },
    },
  },
})

vim.lsp.config('tailwindcss', {
  capabilities = capabilities,
  on_attach = on_attach,
  settings = {
    tailwindCSS = {
      experimental = {
        classRegex = {
          "tw`([^`]*)",
          'tw="([^"]*)',
          'tw={"([^"}]*)',
          "tw\\.\\w+`([^`]*)",
          "tw\\(.*?\\)`([^`]*)",
        },
      },
    },
  },
})

vim.lsp.config('yamlls', {
  capabilities = capabilities,
  on_attach = on_attach,
  settings = {
    yaml = {
      schemas = {
        ["https://json.schemastore.org/github-workflow.json"] = "/.github/workflows/*",
        ["https://json.schemastore.org/github-action.json"] = "/.github/action.{yml,yaml}",
        ["https://json.schemastore.org/ansible-stable-2.9.json"] = "roles/tasks/*.{yml,yaml}",
      },
      validate = true,
      format = { enable = true },
      hover = true,
      completion = true,
    },
  },
})

-- Enable LSP servers
vim.lsp.enable({
  "lua_ls",
  "rust_analyzer",
  "clangd",
  "eslint",
  "pyrefly",
  "ts_ls",
  "tailwindcss",
  "bashls",
  "yamlls",
  "marksman",
})
