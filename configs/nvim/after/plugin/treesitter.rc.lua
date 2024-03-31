
local status, ts = pcall(require, "nvim-treesitter.configs")
if (not status) then return end
ts.build = ":TSUpdate"
ts.setup {
    highlight = {
        enable = true,
        disable = {},
    },
    indent = {
        enable = true,
        disable = {},
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
        "kotlin"
    },
    autotag = {
        enable = true,
    },
    markdown = {
        enable = true,
    },
}
