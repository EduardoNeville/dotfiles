local navbuddy = require("nvim-navbuddy")
local lspconfig = require("lspconfig")

-- Common on_attach function
local function on_attach(client, bufnr)
    navbuddy.attach(client, bufnr)
end

-- List of LSP servers to setup
local servers = { "clangd", "pyright", "tsserver", "bashls"}

-- Setup each LSP server with the common on_attach function
for _, server in ipairs(servers) do
    lspconfig[server].setup {
        on_attach = on_attach
    }
end
