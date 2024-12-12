
return {
    
    "nvim-telescope/telescope.nvim",
    lazy = false,
    version = '0.1.4',
    dependencies = { { 'nvim-lua/plenary.nvim' } },
    config = function ()
        require('telescope').setup{
          defaults = {
            file_ignore_patterns = {
              "node_modules"
            },
            preview = {
                filesize_limit = 0.5, -- MB
            },
          }
        }
    end
}
