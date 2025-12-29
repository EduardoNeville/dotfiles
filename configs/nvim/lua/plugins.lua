---------------------------------------------------------------
------- NVIM plugins ------------------------------------------
---------------------------------------------------------------
return {
    ---------------------------------------------------------------
    ------- LSP configs -------------------------------------------
    ---------------------------------------------------------------
    --{
    --    "VonHeikemen/lsp-zero.nvim",
    --    branch = 'v1.x',
    --    lazy = false,
    --    dependencies = {
    --        -- LSP Support
    --        { 'neovim/nvim-lspconfig' },                        -- Required
    --        { 'williamboman/mason.nvim',           lazy = true }, -- Optional
    --        { 'williamboman/mason-lspconfig.nvim', lazy = true }, -- Optional

    --        -- Autocompletion
    --        { 'hrsh7th/nvim-cmp',                  lazy = false }, -- Required
    --        { 'hrsh7th/cmp-nvim-lsp',              lazy = false }, -- Required
    --        { 'hrsh7th/cmp-buffer',                lazy = true }, -- Optional
    --        { 'hrsh7th/cmp-path',                  lazy = true }, -- Optional
    --        { 'saadparwaiz1/cmp_luasnip',          lazy = true }, -- Optional
    --        { 'hrsh7th/cmp-nvim-lua',              lazy = true }, -- Optional

    --        -- Snippets
    --        { 'L3MON4D3/LuaSnip',                  lazy = false }, -- Required
    --        { 'rafamadriz/friendly-snippets',      lazy = true }, -- Optional
    --    }
    --},

    ---------------------------------------------------------------
    -- LSP + Mason -----------------------------------------------
    ---------------------------------------------------------------
    {
        "williamboman/mason.nvim",
        build = ":MasonUpdate",
        config = function()
            require("mason").setup({
                automatic_installation = false,
            })
        end,
    },

    {
        "williamboman/mason-lspconfig.nvim",
        dependencies = { "mason.nvim" },
        config = function()
            require("mason-lspconfig").setup({
                ensure_installed = {
                    "lua_ls",
                    "rust_analyzer",
                    "clangd",
                    "eslint",
                    "ts_ls",
                    "tailwindcss",
                    "bashls",
                    "yamlls",
                    "marksman",
                },
            })
        end,
    },

    {
        "neovim/nvim-lspconfig",
        dependencies = {
            "mason.nvim",
            "mason-lspconfig.nvim",
            "SmiteshP/nvim-navic",
            "SmiteshP/nvim-navbuddy",
            "MunifTanjim/nui.nvim",
        },
        config = function()
            require("lsp-config.language-server")
        end,
    },

    {
        "SmiteshP/nvim-navbuddy",
        dependencies = {
            "SmiteshP/nvim-navic",
            "MunifTanjim/nui.nvim"
        },
        opts = { lsp = { auto_attach = false } }
    },

    ---------------------------------------------------------------
    -- Linting and Formatting -------------------------------------
    ---------------------------------------------------------------
    {
        "stevearc/conform.nvim",
        event = { "BufReadPre", "BufNewFile" },
        config = function()
            local conform = require("conform")
            conform.setup({
                formatters_by_ft = {
                    lua = { "stylua" },
                    javascript = { "prettier" },
                    typescript = { "prettier" },
                    javascriptreact = { "prettier" },
                    typescriptreact = { "prettier" },
                    css = { "prettier" },
                    html = { "prettier" },
                    json = { "prettier" },
                    yaml = { "prettier" },
                    markdown = { "prettier" },
                    bash = { "shfmt" },
                    rust = { "rustfmt" },
                },
                format_on_save = {
                    lsp_fallback = true,
                    async = false,
                    timeout_ms = 1000,
                },
            })
            vim.keymap.set({ "n", "v" }, "<leader>mp", function()
                conform.format({
                    lsp_fallback = true,
                    async = false,
                    timeout_ms = 1000,
                })
            end, { desc = "Format file or range (in visual mode)" })
        end,
    },

    {
        "mfussenegger/nvim-lint",
        event = { "BufReadPre", "BufNewFile" },
        config = function()
            local lint = require("lint")
            lint.linters_by_ft = {
                lua = { "luacheck" },
                javascript = { "eslint" },
                typescript = { "eslint" },
                javascriptreact = { "eslint" },
                typescriptreact = { "eslint" },
                bash = { "shellcheck" },
                yaml = { "yamllint" },
                markdown = { "markdownlint" },
            }
            local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })
            vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
                group = lint_augroup,
                callback = function()
                    lint.try_lint()
                end,
            })
            vim.keymap.set("n", "<leader>l", function()
                lint.try_lint()
            end, { desc = "Trigger linting for current file" })
        end,
    },

    ---------------------------------------------------------------
    -- Completion stack -------------------------------------------
    ---------------------------------------------------------------
    { "L3MON4D3/LuaSnip",             build = "make install_jsregexp" },
    { "rafamadriz/friendly-snippets", lazy = true },

    {
        "hrsh7th/nvim-cmp",
        dependencies = {
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-path",
            "hrsh7th/cmp-buffer",
            "saadparwaiz1/cmp_luasnip",
            "L3MON4D3/LuaSnip",
            "windwp/nvim-autopairs",
        },
        config = function()
            require("lsp-config.cmp-setup") -- loads the plugin itself
            require("cmp_nvim_lsp")         -- capability helper
        end,
    },

    { "hrsh7th/cmp-cmdline",   lazy = true }, -- optional
    { "windwp/nvim-autopairs", opts = {},                             event = "InsertEnter" },


    ----- Debug --------------------------------------------------
    { "mfussenegger/nvim-dap" },
    { "rcarriga/nvim-dap-ui",  requires = { "mfussenegger/nvim-dap" } },

    {
        "iamcco/markdown-preview.nvim",
        cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
        build = "cd app && yarn install",
        init = function()
            vim.g.mkdp_filetypes = { "markdown" }
        end,
        ft = { "markdown" },
    },

    ---------------------------------------------------------------
    ------- UI configs --------------------------------------------
    ---------------------------------------------------------------

    -- Nvim notify
    { "rcarriga/nvim-notify" },

    -- Which-key
    {
        "folke/which-key.nvim",
        event = "VeryLazy",
        init = function()
            vim.o.timeout = true
            vim.o.timeoutlen = 300
            local presets = require("which-key.plugins.presets")
            presets.operators["i"] = nil
        end,
    },

    -- Fuzzy Finder
    {
        "nvim-telescope/telescope.nvim",
        lazy = false,
        version = '0.1.4',
        dependencies = { { 'nvim-lua/plenary.nvim' } }
    },

    -- Indentations
    {
        "lukas-reineke/indent-blankline.nvim",
        main = "ibl",
        lazy = false,
        opts = {
            scope = { enabled = true, show_start = true, },
            indent = { smart_indent_cap = true, },
        }
    },

    -- Status line with lualine
    {
        'nvim-lualine/lualine.nvim',
        dependencies = { 'nvim-tree/nvim-web-devicons' }
    },

    -- Colour for #HEX
    { "norcalli/nvim-colorizer.lua" },

    -- Nnn
    {
        "luukvbaal/nnn.nvim",
        config = function()
            require("nnn").setup()
        end
    },

    {
        'stevearc/oil.nvim',
        ---@module 'oil'
        ---@type oil.SetupOpts
        opts = {},
        -- Optional dependencies
        dependencies = { { "echasnovski/mini.icons", opts = {} } },
        -- dependencies = { "nvim-tree/nvim-web-devicons" }, -- use if you prefer nvim-web-devicons
        -- Lazy loading is not recommended because it is very tricky to make it work correctly in all situations.
        lazy = false,
    },

    { "xiyaowong/transparent.nvim" },

    {
        "jackMort/ChatGPT.nvim",
        event = "VeryLazy",
        config = function()
            require("chatgpt").setup({
                -- lazyional configuration
                openai_params = {
                    model = "gpt-4o"
                },
                openai_edit_params = {
                    model = "gpt-4o"
                },
            })
        end,
        dependencies = {
            "MunifTanjim/nui.nvim",
            "nvim-lua/plenary.nvim",
            "folke/trouble.nvim",
            "nvim-telescope/telescope.nvim"
        }
    },

    ---------------------------------------------------------------
    ------- Syntax configs ----------------------------------------
    ---------------------------------------------------------------

    {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        config = function()
            require 'nvim-treesitter.configs'.setup {
                highlight = {
                    enable = true,
                    additional_vim_regex_highlighting = false,
                },
                indent = {
                    enable = true,
                },
                incremental_selection = {
                    enable = true,
                    keymaps = {
                        init_selection = "gnn",
                        node_incremental = "grn",
                        scope_incremental = "grc",
                        node_decremental = "grm",
                    },
                },
                textobjects = {
                    select = {
                        enable = true,
                        lookahead = true,
                        keymaps = {
                            ["af"] = "@function.outer",
                            ["if"] = "@function.inner",
                            ["ac"] = "@class.outer",
                            ["ic"] = "@class.inner",
                        },
                    },
                    move = {
                        enable = true,
                        set_jumps = true,
                        goto_next_start = {
                            ["]m"] = "@function.outer",
                            ["]]"] = "@class.outer",
                        },
                        goto_next_end = {
                            ["]M"] = "@function.outer",
                            ["]["] = "@class.outer",
                        },
                        goto_previous_start = {
                            ["[m"] = "@function.outer",
                            ["[["] = "@class.outer",
                        },
                        goto_previous_end = {
                            ["[M"] = "@function.outer",
                            ["[]"] = "@class.outer",
                        },
                    },
                },
                ensure_installed = {
                    "lua_ls",
                    "rust_analyzer",
                    "clangd",
                    "eslint",
                    "tsserver",
                    "tailwindcss",
                    "bashls",
                    "yamlls",
                    "marksman",
                },
                autotag = {
                    enable = true,
                },
                markdown = {
                    enable = true,
                },
            }
        end,
    },

    {
        "cameron-wags/rainbow_csv.nvim",
        config = function()
            require 'rainbow_csv'.setup()
        end,
        -- lazyional lazy-loading below
        module = {
            'rainbow_csv',
            'rainbow_csv.fns'
        },
        ft = {
            'csv',
            'tsv',
            'csv_semicolon',
            'csv_whitespace',
            'csv_pipe',
            'rfc_csv',
            'rfc_semicolon'
        }
    },

    {
        "kylechui/nvim-surround",
        version = "*", -- Use for stability; omit to  `main` branch for the latest features
        config = function()
            require("nvim-surround").setup({
                -- Configuration here, or leave empty to  defaults
            })
        end
    },

    -- Flash and others
    {
        "folke/flash.nvim",
        event = "VeryLazy",
        ---@type Flash.Config
        opts = {},
        -- stylua: ignore
        keys = {
            { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
        },
    },

    -- F movements
    {
        "jinh0/eyeliner.nvim",
        lazy = true,
        config = function()
            require 'eyeliner'.setup {
                highlight_on_key = true,
                dim = true,
            }
        end
    },

    -- Marks signature
    { "kshenoy/vim-signature" },

    ---------------------------------------------------------------
    ------- Colour Schemes configs --------------------------------
    ---------------------------------------------------------------
    { "samharju/synthweave.nvim" },
    { "maxmx03/fluoromachine.nvim", event = "VeryLazy" },
}
