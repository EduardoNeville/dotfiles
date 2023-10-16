local vim = vim

-- Requirements
local navbuddy = require("nvim-navbuddy")

----------------------------------------------------------------------
--- LSP --------------------------------------------------------------
----------------------------------------------------------------------

if not require'lspconfig.configs'.hdl_checker then
  require'lspconfig.configs'.hdl_checker = {
    default_config = {
    cmd = {"hdl_checker", "--lsp", };
    filetypes = {"vhdl", "verilog", "systemverilog"};
      root_dir = function(fname)
        -- will look for the .hdl_checker.config file in parent directory, a
        -- .git directory, or else use the current directory, in that order.
        local util = require'lspconfig'.util
        return util.root_pattern('.hdl_checker.config')(fname) or util.find_git_ancestor(fname) or util.path.dirname(fname)
      end;
      settings = {};
    };
  }
end

require'lspconfig'.hdl_checker.setup{}

----------------------------------------------------------------------
----------------------------------------------------------------------
--- Mason ------------------------------------------------------------
----------------------------------------------------------------------
----------------------------------------------------------------------

-- List of LSP servers to install with Mason and activate in LspConfig
local lsp_servers = {
    pyright = {},
    clangd = {},
    tsserver = {},
    html = {},
    lua_ls = {},
    sqlls = {},
    dockerls = {},
    metals = {},
    emmet_ls = {
        capabilities = vim.lsp.protocol.make_client_capabilities(),
        filetypes = {"css", "html", "javascript", "javascriptreact", "typescriptreact"},
        init_options = {
            html = {
                options = {
                    ["bem.enabled"] = true,
                },
            },
        },
    },
    --rome = {},
    --ruff_lsp = {},
    --eslint = {},
    --jsonls = {},
    --terraformls = {},
    --tflint = {},
    --sumneko_lua = { Lua = { diagnostics = { globals = { "vim" } } } },
    --yamlls = {},
    --
}
-- Setup Mason and auto-install some LSPs
-- Mason handles the actual installations,
-- while mason-lspconfig does the automatation
-- and linking with neovim-lspconfig
require("mason").setup()
require("mason-lspconfig").setup({
    ensure_installed = lsp_servers,
    automatic_installation = true,
})

-- Null-ls is used to set up linters, formatters etc
-- This is the method recommended by mason-null-ls
-- Similar to above, null-ls handles the link with
-- lspconfig, while mason-null-ls handles auto-install
-- and gets Mason to install the things
require("mason-null-ls").setup({
    ensure_installed = {
        "stylua",
        "jq",
        "isort",
        "black",
        "prettierd",
        "debugpy",
        "ruff",
        -- "mypy",
    },
    automatic_installation = true,
    automatic_setup = true,
})
require("null-ls").setup()
--require("mason-null-ls").setup_handlers()

-- COQ autocomplete needed to be set up here
vim.g.coq_settings = {
    auto_start = "shut-up",
    keymap = {
        jump_to_mark = "", -- Prevent clash with split jumping
        --eval_snips = "<leader>j",
    },
}

local coq = require("coq")

-- The null-ls stuff is activated automatically up above
-- by `setup_handlers()`, but the LSP servers need to be
-- manually set up here. Each one is setup() and COQ is
-- activated for them at the same time.
for lsp, settings in pairs(lsp_servers) do
    require("lspconfig")[lsp].setup(coq.lsp_ensure_capabilities({
        on_attach = function(client, buffer)
            server_maps({ buffer = buffer })
            navbuddy.attach(client, buffer)
        end,
        settings = settings,
    }))
end


