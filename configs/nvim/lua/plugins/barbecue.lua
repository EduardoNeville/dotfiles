return {
    "utilyre/barbecue.nvim",
    name = "barbecue",
    version = "*",
    dependencies = {
        "SmiteshP/nvim-navic",
    },
    opts = {
        -- configurations go here
    },
    config = function()
        local status, barbecue = pcall(require, "barbecue")
        if (not status) then return end

        local function get_barbecue_theme()
            if vim.g.theme_is_light then
                -- Light mode: softer, high-contrast colors
                return {
                    normal = { fg = "#1A1A2E" },
                    ellipsis = { fg = "#9CA0B0" },
                    separator = { fg = "#9CA0B0" },
                    modified = { fg = "#D20F39" },
                    dirname = { fg = "#6C6F85" },
                    basename = { bold = true },
                    context = {},
                    context_file = { fg = "#1E66F5" },
                    context_module = { fg = "#8839EF" },
                    context_namespace = { fg = "#8839EF" },
                    context_package = { fg = "#8839EF" },
                    context_class = { fg = "#D20F39" },
                    context_method = { fg = "#1E66F5" },
                    context_property = { fg = "#179299" },
                    context_field = { fg = "#179299" },
                    context_constructor = { fg = "#EA76CB" },
                    context_enum = { fg = "#8839EF" },
                    context_interface = { fg = "#8839EF" },
                    context_function = { fg = "#1E66F5" },
                    context_variable = { fg = "#D20F39" },
                    context_constant = { fg = "#EA76CB" },
                    context_string = { fg = "#40A02B" },
                    context_number = { fg = "#D20F39" },
                    context_boolean = { fg = "#D20F39" },
                    context_array = { fg = "#DF8E1D" },
                    context_object = { fg = "#DF8E1D" },
                    context_key = { fg = "#1E66F5" },
                    context_null = { fg = "#6C6F85" },
                    context_enum_member = { fg = "#179299" },
                    context_struct = { fg = "#8839EF" },
                    context_event = { fg = "#EA76CB" },
                    context_operator = { fg = "#1A1A2E" },
                    context_type_parameter = { fg = "#DF8E1D" },
                }
            else
                -- Dark mode: synthweave-inspired colors
                return {
                    normal = { fg = "#c0caf5" },
                    ellipsis = { fg = "#737aa2" },
                    separator = { fg = "#737aa2" },
                    modified = { fg = "#737aa2" },
                    dirname = { fg = "#737aa2" },
                    basename = { bold = true },
                    context = {},
                    context_file = { fg = "#ac8fe4" },
                    context_module = { fg = "#ac8fe4" },
                    context_namespace = { fg = "#ac8fe4" },
                    context_package = { fg = "#ac8fe4" },
                    context_class = { fg = "#ac8fe4" },
                    context_method = { fg = "#ac8fe4" },
                    context_property = { fg = "#ac8fe4" },
                    context_field = { fg = "#ac8fe4" },
                    context_constructor = { fg = "#ac8fe4" },
                    context_enum = { fg = "#ac8fe4" },
                    context_interface = { fg = "#ac8fe4" },
                    context_function = { fg = "#ac8fe4" },
                    context_variable = { fg = "#ac8fe4" },
                    context_constant = { fg = "#ac8fe4" },
                    context_string = { fg = "#ac8fe4" },
                    context_number = { fg = "#ac8fe4" },
                    context_boolean = { fg = "#ac8fe4" },
                    context_array = { fg = "#ac8fe4" },
                    context_object = { fg = "#ac8fe4" },
                    context_key = { fg = "#ac8fe4" },
                    context_null = { fg = "#ac8fe4" },
                    context_enum_member = { fg = "#ac8fe4" },
                    context_struct = { fg = "#ac8fe4" },
                    context_event = { fg = "#ac8fe4" },
                    context_operator = { fg = "#ac8fe4" },
                    context_type_parameter = { fg = "#ac8fe4" },
                }
            end
        end

        local function setup_barbecue()
            local theme = get_barbecue_theme()

            barbecue.setup({
                attach_navic = true,
                create_autocmd = true,
                include_buftypes = { "" },
                exclude_filetypes = { "netrw", "toggleterm" },
                modifiers = {
                    dirname = ":~:.",
                    basename = "",
                },
                show_dirname = true,
                show_basename = true,
                show_modified = false,
                modified = function(bufnr) return vim.bo[bufnr].modified end,
                show_navic = true,
                lead_custom_section = function() return " " end,
                custom_section = function() return " " end,
                theme = theme,
                context_follow_icon_color = false,
                symbols = {
                    modified = "●",
                    ellipsis = "…",
                    separator = "",
                },
                kinds = {
                    File = "",
                    Module = "",
                    Namespace = "",
                    Package = "",
                    Class = "",
                    Method = "",
                    Property = "",
                    Field = "",
                    Constructor = "",
                    Enum = "",
                    Interface = "",
                    Function = "",
                    Variable = "",
                    Constant = "",
                    String = "",
                    Number = "",
                    Boolean = "",
                    Array = "",
                    Object = "",
                    Key = "",
                    Null = "",
                    EnumMember = "",
                    Struct = "",
                    Event = "",
                    Operator = "",
                    TypeParameter = "",
                },
            })
        end

        setup_barbecue()

        -- Re-setup on theme change
        vim.api.nvim_create_autocmd("User", {
            pattern = "ThemeChanged",
            callback = setup_barbecue,
        })
    end
}
