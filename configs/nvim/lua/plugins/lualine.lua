return {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
        local status, lualine = pcall(require, "lualine")
        if (not status) then return end

        -- Custom ayu theme tweaks for dark mode
        local function get_ayu_theme()
            local custom_ayu = require('lualine.themes.ayu')
            custom_ayu.normal.c.fg = "#7aa2f7"
            return custom_ayu
        end

        local function get_line_count()
            local file = io.open(vim.fn.expand('%'), 'r')
            if not file then
                return ''
            end
            local line_count = 0
            for _ in file:lines() do
                line_count = line_count + 1
            end
            line_count = "󰼭 " .. line_count
            file:close()
            return line_count
        end

        local function get_lualine_theme()
            if vim.g.theme_is_light then
                -- Catppuccin lualine theme auto-detects latte flavour
                return "catppuccin"
            else
                return get_ayu_theme()
            end
        end

        local function setup_lualine()
            require('lualine').setup {
                options = {
                    icons_enabled = true,
                    theme = get_lualine_theme(),
                    section_separators = { left = '', right = '' },
                    component_separators = { left = '│', right = '│' },
                    disabled_filetypes = {}
                },
                sections = {
                    lualine_a = { 'mode' },
                    lualine_b = { 'branch' },
                    lualine_c = { {
                        'filename',
                        file_status = true,
                        path = 0
                    } },
                    lualine_x = {
                        {
                            'diagnostics',
                            sources = { "nvim_diagnostic" },
                            symbols = { error = ' ', warn = ' ', info = ' ', hint = ' ' } },
                        'filetype'
                    },
                    lualine_y = {},
                    lualine_z = { 'location', get_line_count }
                },
                inactive_sections = {
                    lualine_a = {},
                    lualine_b = {},
                    lualine_c = { {
                        'filename',
                        file_status = true,
                        path = 1
                    } },
                    lualine_x = { 'location' },
                    lualine_y = {},
                    lualine_z = {}
                },
                tabline = {},
                extensions = { 'fugitive' }
            }
        end

        -- Initial setup
        setup_lualine()

        -- Re-setup on theme change
        vim.api.nvim_create_autocmd("User", {
            pattern = "ThemeChanged",
            callback = setup_lualine,
        })
    end
}
