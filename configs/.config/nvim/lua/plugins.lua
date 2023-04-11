local status, packer = pcall(require, 'packer')
if (not status) then
        print("Packer is not installed")
        return
end

vim.cmd [[packadd packer.nvim]]

return require('packer').startup(function(use)
        -- Packer can manage itself
        use 'wbthomason/packer.nvim'
        
        -- Copilot
        -- setup up in pack by cloning the repo

        -- Set up your configuration
        use 'lukas-reineke/indent-blankline.nvim' -- Indentations
        use 'kyazdani42/nvim-web-devicons' -- File icons
        use { -- Status Line
        'nvim-lualine/lualine.nvim',
        requires = { 'kyazdani42/nvim-web-devicons', opt = true }
        }
        use 'tpope/vim-fugitive' -- Git

        -- Colour Schemes 
        
        --use 'folke/tokyonight.nvim'
        --vim.cmd("colorscheme tokyonight-storm")
        use 'rose-pine/neovim'
        vim.cmd("colorscheme rose-pine-moon")

        -- Syntax

        use {
                'nmac427/guess-indent.nvim',
                config = function() require('guess-indent').setup {} end,
        }
        -- Syntax highlighting
        use {
        'nvim-treesitter/nvim-treesitter',
        run = ':TSUpdate'
        }
        use 'Shougo/deoplete.nvim' -- Autocomplete

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



