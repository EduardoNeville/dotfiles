local ensure_packer = function()
    local fn = vim.fn
    local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'
        if fn.empty(fn.glob(install_path)) > 0 then
            fn.system({'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path})
            vim.cmd [[packadd packer.nvim]]
            return true
        end
    return false
end

return require('packer').startup(function()
    --- Packer can manage itself
    use 'wbthomason/packer.nvim'

---------------------------------------------------------------
------- LSP configs -------------------------------------------
---------------------------------------------------------------

    -- Added this plugin.
    use {'neovim/nvim-lspconfig'}             -- Required
    use {'williamboman/mason.nvim'}           -- Optional
    use {'williamboman/mason-lspconfig.nvim'} -- Optional

    -- Autocompletion
    use {'hrsh7th/nvim-cmp'}         -- Required
    use {'hrsh7th/cmp-nvim-lsp'}     -- Required
    use {'hrsh7th/cmp-buffer'}       -- Optional
    use {'hrsh7th/cmp-path'}         -- Optional
    use {'saadparwaiz1/cmp_luasnip'} -- Optional
    use {'hrsh7th/cmp-nvim-lua'}     -- Optional

    -- Snippets
    use {'L3MON4D3/LuaSnip'}             -- Required
    use {'rafamadriz/friendly-snippets'} -- Optional
    use {
        'VonHeikemen/lsp-zero.nvim',
        branch = 'v1.x',
        dependencies = {
            -- LSP Support
            {'neovim/nvim-lspconfig'},             -- Required
            {'williamboman/mason.nvim'},           -- Optional
            {'williamboman/mason-lspconfig.nvim'}, -- Optional

            -- Autocompletion
            {'hrsh7th/nvim-cmp'},         -- Required
            {'hrsh7th/cmp-nvim-lsp'},     -- Required
            {'hrsh7th/cmp-buffer'},       -- Optional
            {'hrsh7th/cmp-path'},         -- Optional
            {'saadparwaiz1/cmp_luasnip'}, -- Optional
            {'hrsh7th/cmp-nvim-lua'},     -- Optional

            -- Snippets
            {'L3MON4D3/LuaSnip'},             -- Required
            {'rafamadriz/friendly-snippets'}, -- Optional
        }
    }

    --- Copilot ------------------------------------------
    -- Cloned separately using full_install.sh

---------------------------------------------------------------
------- UI configs -------------------------------------------
---------------------------------------------------------------

    -- Fuzzy Finder
    use {
        'nvim-telescope/telescope.nvim',
        tag = '0.1.4',
        requires = { {'nvim-lua/plenary.nvim'} }
    }

    -- Indentations
    use {
        'lukas-reineke/indent-blankline.nvim',
        tag = 'v3.3.7',
        config = function()
            require("ibl").setup {
                scope = {enabled = true, show_start = true,},
                indent = { smart_indent_cap = true,},
            }
        end
    }

    -- File icons
    use 'kyazdani42/nvim-web-devicons'
    -- Status line with lualine
    use {
        'nvim-lualine/lualine.nvim',
        tag = 'compat-nvim-0.6',
        requires = {
            'kyazdani42/nvim-web-devicons',
            opt = true
        }
    }
    -- Tree directory using nvim-tree
    use {
        'nvim-tree/nvim-tree.lua',
        tag = 'nightly',
        config = function()
            require("nvim-tree").setup {}
        end
    }

    -- Colour for #HEX 
    use {'norcalli/nvim-colorizer.lua',
        config = function()
            require("colorizer").setup {}
        end;
    }

    -- Nnn
    use {
      "luukvbaal/nnn.nvim",
      config = function() require("nnn").setup() end
    }

    -- WinBar using barbecue
    use({
        "utilyre/barbecue.nvim",
        tag = "v1.2.0",
        requires = {
            "SmiteshP/nvim-navic",
            "nvim-tree/nvim-web-devicons", -- optional dependency
        },
        --after = "nvim-web-devicons", -- keep this if you're using NvChad
        config = function()
            require("barbecue").setup()
        end,
    })

    -- File navigator using navbuddy
    use {
        "SmiteshP/nvim-navbuddy",
        requires = {
            "neovim/nvim-lspconfig",
            "SmiteshP/nvim-navic",
            "MunifTanjim/nui.nvim",
            "numToStr/Comment.nvim",        -- Optional
            "nvim-telescope/telescope.nvim" -- Optional
        }
    }

    use "xiyaowong/transparent.nvim"

    -- Markdown Preview
    use({
        "iamcco/markdown-preview.nvim",
        tag = 'v0.0.10',
        run = function() vim.fn["mkdp#util#install"]() end,
    })

    use({
        -- Config is on the treesitter.rc.lua file
        "tadmccorkle/markdown.nvim",
    })

    use({"jackMort/ChatGPT.nvim",
        config = function()
            require("chatgpt").setup({
                -- optional configuration
                openai_params = {
                    model="gpt-4-1106-preview"
                }, 
                openai_edit_params = {
                    model="gpt-4-1106-preview"
                },
            })
        end,
        requires = {
            "MunifTanjim/nui.nvim",
            "nvim-lua/plenary.nvim",
            "nvim-telescope/telescope.nvim"
        }
    })

    use {
        'wfxr/minimap.vim',
        run = ':!cargo install --locked code-minimap'
    }

---------------------------------------------------------------
------- Syntax configs -------------------------------------------
---------------------------------------------------------------

    use 'nvim-treesitter/nvim-treesitter-context'
    --use 'nvim-treesitter/nvim-treesitter'
    -- tree-sitter
    use { 'nvim-treesitter/nvim-treesitter' , 
        run = ':TSUpdate',
        config = function()
            require'nvim-treesitter.configs'.setup {
                highlight = {
                    enable = true,
                },
            }
        end,}

    use {
        'cameron-wags/rainbow_csv.nvim',
        config = function()
            require 'rainbow_csv'.setup()
        end,
        -- optional lazy-loading below
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
    }

    use({
        "kylechui/nvim-surround",
        tag = "*", -- Use for stability; omit to use `main` branch for the latest features
        config = function()
            require("nvim-surround").setup({
                -- Configuration here, or leave empty to use defaults
            })
        end
    })

    -- Flash and others
    use 'ggandor/leap.nvim'


    -- F movements
    use {
      'jinh0/eyeliner.nvim',
      config = function()
        require'eyeliner'.setup {
          highlight_on_key = true,
          dim = true,
        }
      end
    }

    -- Marks signature
    use 'kshenoy/vim-signature'

    use 'prettier/vim-prettier'

    -- Guess Indentations
    -- using packer.nvim
    use {
        'nmac427/guess-indent.nvim',
        config = function() require('guess-indent').setup {} end,
    }

---------------------------------------------------------------
------- Colour Schemes configs --------------------------------
---------------------------------------------------------------

    use 'fcpg/vim-farout'
    use 'folke/tokyonight.nvim'
    use {"bluz71/vim-moonfly-colors", as = "moonfly"}
    use 'maxmx03/fluoromachine.nvim'
    use "EdenEast/nightfox.nvim"
    use {"nobbmaestro/nvim-andromeda", requires = { "tjdevries/colorbuddy.nvim", branch = "dev" }}
    use 'zanglg/nova.nvim'
    use 'jaredgorski/SpaceCamp'
    use {'nyngwang/nvimgelion'}
    use 'Shatur/neovim-ayu'
    use "samharju/synthweave.nvim"

-- run :colorscheme synthweave or synthweave-transparent when feeling like it
    --- Colorscheme config ----------------------------------------
    --local fm = require 'fluoromachine'
    --fm.setup {
    --    glow = false,
    --    theme = 'retrowave',
    --    transparent = "full",
    --    overrides = {
    --        ['@type'] = { italic = true, bold = false },
    --        ['@function'] = { italic = false, bold = false },
    --        ['@comment'] = { italic = true , bold = false},
    --        ['@keyword'] = { italic = false , bold= false},
    --        ['@constant'] = { italic = false, bold = false },
    --        ['@variable'] = { italic = true , bold= false},
    --        ['@field'] = { italic = true , bold= false},
    --        ['@parameter'] = { italic = true , bold= false},
    --    },
    --    colors = function(_, d)
    --        return {
    --            bg = '#190920',
    --            alt_bg = d('#190920', 20),
    --            cyan = '#49eaff',
    --            red = '#ff1e34',
    --            yellow = '#ffe756',
    --            comment = '#57ff00',
    --            orange = '#f38e21',
    --            pink = '#ffadff',
    --            purple = '#9544f7'}
    --        end
    --}
    ----vim.cmd.colorscheme('fluoromachine')
    --vim.cmd.colorscheme('blue')
end)
