return {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
        local status, ts = pcall(require, "nvim-treesitter.configs")
        if (not status) then return end
        ts.setup {
            highlight = {
                enable = true,
                additional_vim_regex_highlighting = false,
                disable = {},
            },
            indent = {
                enable = true,
                disable = {},
            },
            incremental_selection = {
                enable = true,
                keymaps = {
                    init_selection = "gnn",
                    node_incremental = "grn",
                    scope_incremental = "grc",
                    node_decremental = "grm",
                },
            },
            textobjects = {
                select = {
                    enable = true,
                    lookahead = true,
                    keymaps = {
                        ["af"] = "@function.outer",
                        ["if"] = "@function.inner",
                        ["ac"] = "@class.outer",
                        ["ic"] = "@class.inner",
                    },
                },
                move = {
                    enable = true,
                    set_jumps = true,
                    goto_next_start = {
                        ["]m"] = "@function.outer",
                        ["]]"] = "@class.outer",
                    },
                    goto_next_end = {
                        ["]M"] = "@function.outer",
                        ["]["] = "@class.outer",
                    },
                    goto_previous_start = {
                        ["[m"] = "@function.outer",
                        ["[["] = "@class.outer",
                    },
                    goto_previous_end = {
                        ["[M"] = "@function.outer",
                        ["[]"] = "@class.outer",
                    },
                },
            },
            ensure_installed = {
                "markdown",
                "markdown_inline",
                "cpp",
                "python",
                "c",
                "scala",
                "rust",
                "css",
                "html",
                "lua",
                "sql",
                "vim",
                "glsl",
                "javascript",
                "typescript",
                "bash",
                "kotlin",
                "yaml"
            },
            autotag = {
                enable = true,
            },
            markdown = {
                enable = true,
            },
        }
    end
}
