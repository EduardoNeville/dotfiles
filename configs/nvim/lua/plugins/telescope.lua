return {
    "nvim-telescope/telescope.nvim",
    lazy = false,
    branch = 'master',
    dependencies = { { 'nvim-lua/plenary.nvim' } },
    config = function()
        require('telescope').setup {
            defaults = {
                file_ignore_patterns = {
                    "node_modules"
                },
                preview = {
                    filesize_limit = 0.5, -- MB
                    treesitter = false,
                },
            }
        }
    end
}
