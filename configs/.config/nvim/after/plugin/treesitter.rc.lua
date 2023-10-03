
local status, ts = pcall(require, "nvim-treesitter.configs")
if (not status) then return end

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
        "javascript"
    },
    autotag = {
            enable = true,
    },
}
