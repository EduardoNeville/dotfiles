local vim = vim

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

    -------------------------------------
    -------------------------------------
    -- LSP configs
    -------------------------------------
    -------------------------------------
    use 'neovim/nvim-lspconfig'
    use 'williamboman/mason.nvim'
    use 'williamboman/mason-lspconfig.nvim'
    use 'jose-elias-alvarez/null-ls.nvim'
    use 'jay-babu/mason-null-ls.nvim'
    use({ "ms-jpq/coq_nvim", branch = "coq" })
    --use ("hrsh7th/cmp-nvim-lsp")

    -- Scala metals LSP
    use({'scalameta/nvim-metals',
        requires = { "nvim-lua/plenary.nvim" }
    })
    use 'nanotee/sqls.nvim'

    -- Copilot
    -- setup up in pack by cloning the repo

    -------------------------------------
    -------------------------------------
    -- UI 
    -------------------------------------
    -------------------------------------

    use 'lukas-reineke/indent-blankline.nvim' -- Indentations
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
             -- or                            , branch = '0.1.x',
            requires = { {'nvim-lua/plenary.nvim'} }
    }
    use 'BurntSushi/ripgrep'

    -- Markdown Preview
    -- install without yarn or npm
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
          })
        end,
        requires = {
            "MunifTanjim/nui.nvim",
            "nvim-lua/plenary.nvim",
            "nvim-telescope/telescope.nvim"
        }
    })

    --use 'luk400/vim-jukit'
    --use 'tpope/vim-fugitive' -- Git

    -------------------------------------
    -- Syntax highlighting
    -------------------------------------
    use 'nvim-treesitter/nvim-treesitter-context'
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

    -- Syntax
    use {
        'nmac427/guess-indent.nvim',
        config = function() require('guess-indent').setup {} end,
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

    -------------------------------------
    -------------------------------------
    -- Colour Schemes 
    -------------------------------------
    -------------------------------------

    use 'fcpg/vim-farout'
    use 'folke/tokyonight.nvim'
    use { "bluz71/vim-moonfly-colors", as = "moonfly" }
    use 'maxmx03/fluoromachine.nvim'
    use "EdenEast/nightfox.nvim"
    -- Setting them straight away using this command
    --vim.cmd("colorscheme rose-pine-moon")

    ------------------------------------- 
    ------------------------------------- 
    -- Debugging
    ------------------------------------- 
    ------------------------------------- 

    use "folke/neodev.nvim"
    use 'mfussenegger/nvim-dap'
    use {
        "rcarriga/nvim-dap-ui",
        requires = {"mfussenegger/nvim-dap"}
    }
    use {'mfussenegger/nvim-dap-python',
        ft = "python",
        dependencies = {
            "mfussenegger/nvim-dap",
            "rcarriga/nvim-dap-ui"
        },
        config = function(_, opts)
            local path = "~/.local/share/nvim/mason/packages/debugpy/venv/bin/python"
            require("dap-python").setup(path)
        end,
    }

    -------------------------------------
    -------------------------------------
    -- Misc
    -------------------------------------
    -------------------------------------

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



