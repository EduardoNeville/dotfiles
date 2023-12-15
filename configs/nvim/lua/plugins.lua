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

    --- LSP configs --------------------------------------
    use {'neovim/nvim-lspconfig', tag ='v0.1.6'}
    use {'williamboman/mason.nvim', tag = 'v1.8.3'}
    use {'williamboman/mason-lspconfig.nvim', tag = 'v1.23.0'}
    use 'nvimtools/none-ls.nvim'
    use {'jay-babu/mason-null-ls.nvim', tag = 'v2.1.0'}
    use ({ "ms-jpq/coq_nvim", branch = "coq"})

    --- Coc.nvim ----------------------------------------
    use {'neoclide/coc.nvim', branch = 'release', tag = 'v0.0.82'}

    --- Copilot ------------------------------------------
    --- setup up in pack by cloning the repo 

    --- UI ------------------------------------------------

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

    use {
        "luukvbaal/nnn.nvim",
        config = function() require("nnn").setup({
            picker = {
                cmd = "tmux new-session nnn -Pp",
                offset = true,
            },
            replace_netrw = "picker",
        }) end
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
        "jackMort/ChatGPT.nvim",
        config = function()
            require("chatgpt").setup({
                -- optional configuration
                openai_params = {
                    model="gpt-4-0314"
                }, 
                openai_edit_params = {
                    model="gpt-4-0314"
                },
            })
        end,
        requires = {
            "MunifTanjim/nui.nvim",
            "nvim-lua/plenary.nvim",
            "nvim-telescope/telescope.nvim"
        }
    })

    use({
        "aserowy/tmux.nvim",
        config = function() return require("tmux").setup() end
    })

    --- Syntax highlighting ----------------------------------
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

    -- Syntax
    --use {
    --    'nmac427/guess-indent.nvim',
    --    config = function() require('guess-indent').setup {} end,
    --}

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
    use 'ggandor/lightspeed.nvim'

    -- Marks signature
    use 'kshenoy/vim-signature'

    use 'prettier/vim-prettier'

    --- Debugging ------------------------------------------------
    --local debugging = use {
    --    use "folke/neodev.nvim",
    --    --use {
    --    --  "mfussenegger/nvim-dap",
    --    --  opt = true,
    --    --  event = "BufReadPre",
    --    --  module = {"dap"},
    --    --  wants = {"nvim-dap-virtual-text", "DAPInstall.nvim", "nvim-dap-ui", "nvim-dap-python"},
    --    --  requires = {
    --    --    "Pocco81/DAPInstall.nvim",
    --    --    "theHamsta/nvim-dap-virtual-text",
    --    --    "rcarriga/nvim-dap-ui",
    --    --    "mfussenegger/nvim-dap-python",
    --    --    "nvim-telescope/telescope-dap.nvim",
    --    --    { "jbyuki/one-small-step-for-vimkind", module = "osv" },
    --    --  },
    --    --  config = function()
    --    --    require("config.dap").setup()
    --    --  end,
    --    --}
    --}


    --- Misc -----------------------------------------------------
    -- Noice.nvim 
--        use({
--                "folke/noice.nvim",
--                config = function()
--                        require("noice").setup({
--                        -- add any options here
--                  })end,
--                requires = {
--                        -- if you lazy-load any plugin below, make sure to add proper `module="..."` entries
--                        "MunifTanjim/nui.nvim",
--                        -- OPTIONAL:
--                        --   `nvim-notify` is only needed, if you want to use the notification view.
--                        --   If not available, we use `mini` as the fallback
--                        "rcarriga/nvim-notify",
--                }
--        })
    
    --- Colour Schemes ------------------------------------------
    use 'fcpg/vim-farout'
    use 'folke/tokyonight.nvim'
    use {"bluz71/vim-moonfly-colors", as = "moonfly"}
    use 'maxmx03/fluoromachine.nvim'
    use "EdenEast/nightfox.nvim"
    use {"nobbmaestro/nvim-andromeda", requires = { "tjdevries/colorbuddy.nvim", branch = "dev" }
    }
    use 'zanglg/nova.nvim'
    use 'jaredgorski/SpaceCamp'
    use {'nyngwang/nvimgelion'}

    --- Colorscheme config ----------------------------------------
    local fm = require 'fluoromachine'
    fm.setup {
        glow = false,
        theme = 'retrowave',
        transparent = "full",
        overrides = {
            ['@type'] = { italic = true, bold = false },
            ['@function'] = { italic = false, bold = false },
            ['@comment'] = { italic = true , bold = false},
            ['@keyword'] = { italic = false , bold= false},
            ['@constant'] = { italic = false, bold = false },
            ['@variable'] = { italic = true , bold= false},
            ['@field'] = { italic = true , bold= false},
            ['@parameter'] = { italic = true , bold= false},
        },
        colors = function(_, d)
            return {
                bg = '#190920',
                alt_bg = d('#190920', 20),
                cyan = '#49eaff',
                red = '#ff1e34',
                yellow = '#ffe756',
                comment = '#57ff00',
                orange = '#f38e21',
                pink = '#ffadff',
                purple = '#9544f7'}
            end
    }
    vim.cmd.colorscheme('fluoromachine')
end)
