
local on_attach = function(client, bufnr)
  local function buf_set_keymap(...)
    vim.api.nvim_buf_set_keymap(bufnr, ...)
  end
  local function buf_set_option(...)
    vim.api.nvim_buf_set_option(bufnr, ...)
  end

-- Import the lspconfig module
local lspconfig = require('lspconfig')
-- Configure the Pyright language server
lspconfig.pyright.setup{
  on_attach = on_attach
}
-- Configure the Clangd language server
lspconfig.clangd.setup{
  on_attach = on_attach
}

  buf_set_option("omnifunc", "v:lua.vim.lsp.omnifunc")

  local opts = { noremap = true, silent = true }

  buf_set_keymap("n", "gD", "<Cmd>lua vim.lsp.buf.declaration()<CR>", opts) --> gD Jumps to declaration
  buf_set_keymap("n", "gd", "<Cmd>lua vim.lsp.buf.definition()<CR>", opts) --> gd Jumps to definition
  buf_set_keymap("n", "<C-k>", "<Cmd>lua vim.lsp.buf.hover()<CR>", opts) --> Control-K Shows hover info
  buf_set_keymap("n", "<C-j>", "<cmd>lua vim.lsp.buf.signature_help()<CR>", opts) --> Control-J Shows signature help
  buf_set_keymap("n", "gr", ":lua vim.lsp.buf.references()<CR>", opts) --> gr Shows references
  buf_set_keymap("n", "]D", "vim.diagnostic.open_float", opts) --> ]D Shows diagnostics
  buf_set_keymap("n", "[d", "vim.diagnostic.goto_prev", opts) --> [d Show prev diagnostic
  buf_set_keymap("n", "]d", "vim.diagnostic.goto_next", opts) --> ]d Show prev diagnostic

end


local nvim_metals_group = vim.api.nvim_create_augroup("nvim-metals", { clear = true })
  vim.api.nvim_create_autocmd("FileType", {
    pattern = { "scala", "sbt", "java" },
    callback = function()
      require("metals").initialize_or_attach({})
    end,
    group = nvim_metals_group,
  })
