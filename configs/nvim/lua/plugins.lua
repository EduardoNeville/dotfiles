
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

    --- Copilot ------------------------------------------
    -- Cloned separately using full_install.sh

---------------------------------------------------------------
------- UI configs -------------------------------------------
---------------------------------------------------------------

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

    "tadmccorkle/markdown.nvim",

    {
      "jackMort/ChatGPT.nvim",
        event = "VeryLazy",
        config = function()
          require("chatgpt").setup({
                -- lazyional configuration
                openai_params = {
                    model="gpt-4-1106-preview"
                }, 
                openai_edit_params = {
                    model="gpt-4-1106-preview"
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
------- Syntax configs -------------------------------------------
---------------------------------------------------------------

    { "nvim-treesitter/nvim-treesitter-context" },

    --{ 
    --    "nvim-treesitter/nvim-treesitter" ,
    --    config = function()
    --        require'nvim-treesitter.configs'.setup {
    --            highlight = {
    --                enable = true,
    --            },
    --        }
    --    end,
    --},

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
        --{ "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
        --{ "r", mode = "o", function() require("flash").remote() end, desc = "Remote Flash" },
        --{ "<c-s>", mode = { "c" }, function() require("flash").toggle() end, desc = "Toggle Flash Search" },
      },
    },


    -- F movements
    {
        "jinh0/eyeliner.nvim",
        config = function()
            require'eyeliner'.setup {
                highlight_on_key = true,
                dim = true,
            }
        end
    },

    -- Marks signature
	{ "kshenoy/vim-signature" },

	{ "prettier/vim-prettier" },

    -- Guess Indentations
    -- using packer.nvim
    {
        "nmac427/guess-indent.nvim",
        config = function()
            require('guess-indent').setup {}
        end,
    },

---------------------------------------------------------------
------- Colour Schemes configs --------------------------------
---------------------------------------------------------------

     "fcpg/vim-farout",
     "folke/tokyonight.nvim",
     "maxmx03/fluoromachine.nvim",
     "EdenEast/nightfox.nvim",
     {"nobbmaestro/nvim-andromeda", dependencies = { "tjdevries/colorbuddy.nvim", branch = "dev" }},
     "zanglg/nova.nvim",
     "jaredgorski/SpaceCamp",
     "nyngwang/nvimgelion",
     "Shatur/neovim-ayu",
     "samharju/synthweave.nvim",
}

