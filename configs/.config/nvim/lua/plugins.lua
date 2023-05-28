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

vim.cmd [[packadd packer.nvim]]


return require('packer').startup(function(use)
        -- Packer can manage itself
        use 'wbthomason/packer.nvim'


        -- LSP configs
        use ('neovim/nvim-lspconfig') -- LSP
        use ({'williamboman/mason.nvim'})
        use ('williamboman/mason-lspconfig.nvim')
        use({ "jose-elias-alvarez/null-ls.nvim" })
        use({ "jay-babu/mason-null-ls.nvim" })
        use({ "ms-jpq/coq_nvim", branch = "coq" })
        --use ("hrsh7th/cmp-nvim-lsp")
        
        -- Copilot
        -- setup up in pack by cloning the repo

        -------------------------------------
        -------------------------------------
        -- UI 
        -------------------------------------
        -------------------------------------
        
        use 'lukas-reineke/indent-blankline.nvim' -- Indentations
        use 'kyazdani42/nvim-web-devicons' -- File icons
        use { -- Status Line
        'nvim-lualine/lualine.nvim',
        requires = { 'kyazdani42/nvim-web-devicons', opt = true }
        }
        use {
        'nvim-tree/nvim-tree.lua',
        config = function()
                require("nvim-tree").setup {}
                end
        }
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
        use 'nvim-treesitter/nvim-treesitter-context'

        --use 'tpope/vim-fugitive' -- Git

        -- Colour Schemes 
        use 'folke/tokyonight.nvim'
        vim.cmd("colorscheme tokyonight-storm")
        use "EdenEast/nightfox.nvim" 
        --use 'rose-pine/neovim'
        --vim.cmd("colorscheme rose-pine-moon")

        -- Syntax
        use {
                'nmac427/guess-indent.nvim',
                config = function() require('guess-indent').setup {} end,
        }
        -- Syntax highlighting
        use {
        'nvim-treesitter/nvim-treesitter'
        }
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
        -- Markdown Preview
        -- install without yarn or npm
        use({
                "iamcco/markdown-preview.nvim",
                run = function() vim.fn["mkdp#util#install"]() end,
        })

        --use 'Shougo/deoplete.nvim' -- Autocomplete

        -- Fuzzy Finder
        use {
                'nvim-telescope/telescope.nvim', tag = '0.1.1',
                 -- or                            , branch = '0.1.x',
                requires = { {'nvim-lua/plenary.nvim'} }
        }
        use 'BurntSushi/ripgrep'



        --use({ "iamcco/markdown-preview.nvim", run = "cd app && npm install", setup = function() vim.g.mkdp_filetypes = { "markdown" } end, ft = { "markdown" }, })

        use({
            "kylechui/nvim-surround",
            tag = "*", -- Use for stability; omit to use `main` branch for the latest features
            config = function()
                require("nvim-surround").setup({
                    -- Configuration here, or leave empty to use defaults
                })
            end
        })

        use 'MunifTanjim/nui.nvim'
        use 'nvim-lua/plenary.nvim'

        use({
          "jackMort/ChatGPT.nvim",
            config = function()
              require("chatgpt").setup({
                -- optional configuration
              })
            end,
            requires = {
              "MunifTanjim/nui.nvim",
              "nvim-lua/plenary.nvim",
              "nvim-telescope/telescope.nvim"
            }
        })
        
        --
        --LSP
        --
        -- Scala metals LSP
        use({'scalameta/nvim-metals', 
                requires = { "nvim-lua/plenary.nvim" }
        })
        use 'nanotee/sqls.nvim'


        --use 'luk400/vim-jukit'


        --- 
        -- Debugging
        ---
        use "folke/neodev.nvim"
        use 'mfussenegger/nvim-dap'
        use { "rcarriga/nvim-dap-ui", requires = {"mfussenegger/nvim-dap"} }
        use {
          'sakhnik/nvim-gdb',
          run = './install.sh'
        }


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

end)



