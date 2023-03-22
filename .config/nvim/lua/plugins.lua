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
        use 'github/copilot.vim'

        -- Set up your configuration
        use 'lukas-reineke/indent-blankline.nvim' -- Indentations
        use 'kyazdani42/nvim-web-devicons' -- File icons
        use { -- Status Line
        'nvim-lualine/lualine.nvim',
        requires = { 'kyazdani42/nvim-web-devicons', opt = true }
        }
        use 'tpope/vim-fugitive' -- Git

        -- Colour Schemes 
        use 'folke/tokyonight.nvim'
        vim.cmd("colorscheme tokyonight-storm")
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

        use({ "iamcco/markdown-preview.nvim", run = "cd app && npm install", setup = function() vim.g.mkdp_filetypes = { "markdown" } end, ft = { "markdown" }, })

        use({
            "kylechui/nvim-surround",
            tag = "*", -- Use for stability; omit to use `main` branch for the latest features
            config = function()
                require("nvim-surround").setup({
                    -- Configuration here, or leave empty to use defaults
                })
            end
        })
end)



