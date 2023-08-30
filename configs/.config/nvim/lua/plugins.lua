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
    use 'neovim/nvim-lspconfig'
    use 'williamboman/mason.nvim'
    use 'williamboman/mason-lspconfig.nvim'
    use 'jose-elias-alvarez/null-ls.nvim'
    use 'jay-babu/mason-null-ls.nvim'
    use({ "ms-jpq/coq_nvim", branch = "coq" })
    --use ("hrsh7th/cmp-nvim-lsp")
    use 'mattn/emmet-vim'

    -- Scala metals LSP
    use({'scalameta/nvim-metals',
        requires = { "nvim-lua/plenary.nvim" }
    })
    use 'nanotee/sqls.nvim'

    --- Coc.nvim ----------------------------------------
    use {'neoclide/coc.nvim', branch = 'release'}

    --- Copilot ------------------------------------------
    --- setup up in pack by cloning the repo 

    --- UI ------------------------------------------------
    use {
        'lukas-reineke/indent-blankline.nvim', -- Indentations
        config = function()
            require("indent_blankline").setup {
                buftype_exclude = {"terminal"},
                show_current_context = true,
                show_current_context_start = true,
            }
        end
    }
    use 'kyazdani42/nvim-web-devicons' -- File icons
    -- Status line with lualine
    use {
        'nvim-lualine/lualine.nvim',
        requires = {
            'kyazdani42/nvim-web-devicons',
            opt = true
        }
    }
    -- Tree directory using nvim-tree
    use {
        'nvim-tree/nvim-tree.lua',
        config = function()
            require("nvim-tree").setup {}
        end
    }

    use {'Djancyp/better-comments.nvim'}
    use {'norcalli/nvim-colorizer.lua',
        config = function()
            require("colorizer").setup {}
        end;
        }

    use {
        "luukvbaal/nnn.nvim",
        config = function() require("nnn").setup() end
    }

    -- WinBar using barbecue
    use({
        "utilyre/barbecue.nvim",
        tag = "*",
        requires = {
            "SmiteshP/nvim-navic",
            "nvim-tree/nvim-web-devicons", -- optional dependency
        },
        --after = "nvim-web-devicons", -- keep this if you're using NvChad
        config = function()
            require("barbecue").setup()
        end,
    })

    use {
        'chentoast/marks.nvim',
        config = {
            default_mappings = true,
            signs = true,
            mappings = {}
        }
    }

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

    -- Fuzzy Finder
    use {
        'nvim-telescope/telescope.nvim', tag = '0.1.1',
         -- or                         , branch = '0.1.x',
        requires = { {'nvim-lua/plenary.nvim'} }
    }
    use 'BurntSushi/ripgrep'

    -- Markdown Preview
    use({
            "iamcco/markdown-preview.nvim",
            run = function() vim.fn["mkdp#util#install"]() end,
    })

    use 'MunifTanjim/nui.nvim'
    use 'nvim-lua/plenary.nvim'

    use({
      "jackMort/ChatGPT.nvim",
        config = function()
            require("chatgpt").setup({
                -- optional configuration
                openai_params = {
                    model="gpt-4"
                }, 
                openai_edit_params = {
                    model="gpt-4"
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

    --use 'luk400/vim-jukit'
    --use 'tpope/vim-fugitive' -- Git
    --use {
    --    "folke/which-key.nvim",
    --    config = function()
    --        vim.o.timeout = true
    --        vim.o.timeoutlen = 300
    --    end
    --}

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
            custom_captures = {
             -- Highlight the @foo.bar capture group with the "Identifier" highlight group.
             ["foo.bar"] = "Identifier",
            },
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

    use 'ggandor/lightspeed.nvim'

    use 'prettier/vim-prettier'

    --- Colour Schemes ------------------------------------------
    use 'fcpg/vim-farout'
    use 'folke/tokyonight.nvim'
    use {"bluz71/vim-moonfly-colors", as = "moonfly"}
    use 'maxmx03/fluoromachine.nvim'
    use "EdenEast/nightfox.nvim"
    use 'shaunsingh/moonlight.nvim'
    use {
        "nobbmaestro/nvim-andromeda",
        requires = { "tjdevries/colorbuddy.nvim", branch = "dev" }
    }

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
