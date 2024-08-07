---------------------------------------------------------------
------- NVIM plugins ------------------------------------------
---------------------------------------------------------------
return {

---------------------------------------------------------------
------- LSP configs -------------------------------------------
---------------------------------------------------------------
    {
        "VonHeikemen/lsp-zero.nvim",
        branch = 'v1.x',
        lazy = false,
        dependencies = {
            -- LSP Support
            {'neovim/nvim-lspconfig'},             -- Required
            {'williamboman/mason.nvim', lazy = true},           -- Optional
            {'williamboman/mason-lspconfig.nvim', lazy = true}, -- Optional

            -- Autocompletion
            {'hrsh7th/nvim-cmp', lazy = false},         -- Required
            {'hrsh7th/cmp-nvim-lsp', lazy = false},     -- Required
            {'hrsh7th/cmp-buffer', lazy = true},       -- Optional
            {'hrsh7th/cmp-path', lazy = true},         -- Optional
            {'saadparwaiz1/cmp_luasnip', lazy = true}, -- Optional
            {'hrsh7th/cmp-nvim-lua', lazy = true},     -- Optional

            -- Snippets
            {'L3MON4D3/LuaSnip', lazy = false},             -- Required
            {'rafamadriz/friendly-snippets', lazy = true}, -- Optional
        }
    },

    {
        "williamboman/mason.nvim",
        lazy = true,
    },

    --- Copilot ------------------------------------------
    -- Cloned separately using full_install.sh

    {
        "luk400/vim-jukit",
        lazy = true,
    },

---------------------------------------------------------------
------- UI configs -------------------------------------------
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
        dependencies = { {'nvim-lua/plenary.nvim'} }
    },

    -- Indentations
    {
        "lukas-reineke/indent-blankline.nvim",
        main = "ibl",
        lazy = false,
        opts = {
            scope = {enabled = true, show_start = true,},
            indent = { smart_indent_cap = true,},
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
        "SmiteshP/nvim-navbuddy",
        lazy = true,
        dependencies = {
            "neovim/nvim-lspconfig",
            "SmiteshP/nvim-navic",
            "MunifTanjim/nui.nvim",
            "numToStr/Comment.nvim",        -- Optional
            "nvim-telescope/telescope.nvim" -- Optional
        }
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
        "tadmccorkle/markdown.nvim",
        event = "VeryLazy",
    },

    {
      "jackMort/ChatGPT.nvim",
        event = "VeryLazy",
        config = function()
          require("chatgpt").setup({
                -- lazyional configuration
                openai_params = {
                    model="gpt-4o"
                },
                openai_edit_params = {
                    model="gpt-4o"
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
        "nvim-treesitter/nvim-treesitter" ,
        config = function()
            require'nvim-treesitter.configs'.setup {
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
            require'eyeliner'.setup {
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
    { "fcpg/vim-farout", event = "VeryLazy" },
    { "folke/tokyonight.nvim", event = "VeryLazy" },
    { "maxmx03/fluoromachine.nvim", event = "VeryLazy" },
    { "EdenEast/nightfox.nvim", event = "VeryLazy"},
    {"nobbmaestro/nvim-andromeda", event = "VeryLazy",dependencies = { "tjdevries/colorbuddy.nvim", branch = "dev" }},
    { "zanglg/nova.nvim", event = "VeryLazy" },
    { "jaredgorski/SpaceCamp", event = "VeryLazy" },
    { "nyngwang/nvimgelion", event = "VeryLazy" },
    { "Shatur/neovim-ayu", event = "VeryLazy" },
    { "samharju/synthweave.nvim" },
}

