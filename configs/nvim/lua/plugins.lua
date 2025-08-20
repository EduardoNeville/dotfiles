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
      build = ":MasonUpdate",      -- optional: auto-update registries
      config = true,               -- use default config
    },

    {
      "williamboman/mason-lspconfig.nvim",
      dependencies = "mason.nvim", -- make sure Mason is loaded first
      config = true,               -- use default config
    },

    {
      "neovim/nvim-lspconfig",
      dependencies = {
        "mason.nvim",
        "mason-lspconfig.nvim",

        -- optional UI helpers
        "SmiteshP/nvim-navic",
        {
            "SmiteshP/nvim-navbuddy",
            dependencies = {
                "SmiteshP/nvim-navic",
                "MunifTanjim/nui.nvim"
            },
            opts = { lsp = { auto_attach = true } }
        },
        "MunifTanjim/nui.nvim",
      },
      config = function()
        require("lsp-config.language-server")  -- <-- now mason-lspconfig IS loaded
      end,
    },

    ---------------------------------------------------------------
    -- Completion stack -------------------------------------------
    ---------------------------------------------------------------
    { "L3MON4D3/LuaSnip", build = "make install_jsregexp" },
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
        require("lsp-config.cmp-setup")               -- loads the plugin itself
        require("cmp_nvim_lsp")      -- capability helper
      end,
    },

    { "hrsh7th/cmp-cmdline", lazy = true },     -- optional
    { "windwp/nvim-autopairs",  opts = {}, event = "InsertEnter" },


    ----- Debug --------------------------------------------------
    { "mfussenegger/nvim-dap" },
    { "rcarriga/nvim-dap-ui", requires = {"mfussenegger/nvim-dap"} },

    --- Copilot ---------------------------------------------------
    -- Cloned separately using full_install.sh

    -- Avante -----------------------------------------------------
    --{
    --  "yetone/avante.nvim",
    --  event = "VeryLazy",
    --  lazy = false,
    --  version = false, -- set this if you want to always pull the latest change
    --  opts = {
    --    -- add any opts here
    --  },
    --  -- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
    --  build = "make",
    --  -- build = "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false" -- for windows
    --  dependencies = {
    --    "nvim-treesitter/nvim-treesitter",
    --    "stevearc/dressing.nvim",
    --    "nvim-lua/plenary.nvim",
    --    "MunifTanjim/nui.nvim",
    --    --- The below dependencies are optional,
    --    "nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
    --    "zbirenbaum/copilot.lua", -- for providers='copilot'
    --    {
    --      -- support for image pasting
    --      "HakonHarnes/img-clip.nvim",
    --      event = "VeryLazy",
    --      opts = {
    --        -- recommended settings
    --        default = {
    --          embed_image_as_base64 = false,
    --          prompt_for_file_name = false,
    --          drag_and_drop = {
    --            insert_mode = true,
    --          },
    --          -- required for Windows users
    --          use_absolute_path = true,
    --        },
    --      },
    --    },
    --    {
    --      -- Make sure to set this up properly if you have lazy=true
    --      'MeanderingProgrammer/render-markdown.nvim',
    --      opts = {
    --        file_types = { "markdown", "Avante" },
    --      },
    --      ft = { "markdown", "Avante" },
    --    },
    --  },
    --},

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

    -- Markdown Preview
    {
        "iamcco/markdown-preview.nvim",
        cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
        ft = { "markdown" },
        build = function() vim.fn["mkdp#util#install"]() end,
    },

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
        config = function()
            require 'nvim-treesitter.configs'.setup {
                highlight = {
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

