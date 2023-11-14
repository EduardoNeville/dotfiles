local vim = vim 

-- Custom background for duskfox
local custom_duskfox = require'lualine.themes.duskfox'
local custom_nova = require'lualine.themes.nova'
custom_duskfox.normal.c.bg = "#080062"
custom_nova.normal.c.bg = "#080062"

local status, lualine = pcall(require, "lualine")
if (not status) then return end

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

lualine.setup {
    options = {
        icons_enabled = true,
        theme = custom_duskfox, --custom_duskfox, -- custom_nova, -- "nova", -- custom_duskfox, -- "duskfox",
        section_separators = { left = '', right = '' },
        --  
        --   
        --  
        --  │ 
        --  
        --  
        --  
        component_separators = { left = '│', right = '│' },
        disabled_filetypes = {}
    },
    sections = {
        lualine_a = { 'mode' },
        lualine_b = { 'branch' },
        lualine_c = { {
            'filename',
            file_status = true, -- displays file status (readonly status, modified status)
            path = 0 -- 0 = just filename, 1 = relative path, 2 = absolute path
        } },
        lualine_x = {
            { 'diagnostics', sources = { "nvim_diagnostic" }, symbols = { error = ' ', warn = ' ', info = ' ',
              hint = ' ' } },
            'encoding',
            'filetype'
        },
        lualine_y = { 'progress' },
        lualine_z = { 'location', get_line_count }
    },
    inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = { {
            'filename',
            file_status = true, -- displays file status (readonly status, modified status)
            path = 1 -- 0 = just filename, 1 = relative path, 2 = absolute path
        } },
        lualine_x = { 'location' },
        lualine_y = {},
        lualine_z = {}
    },
    tabline = {},
    extensions = { 'fugitive' }
}

