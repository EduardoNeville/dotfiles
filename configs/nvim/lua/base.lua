local vim = vim

-- File encoding
vim.scriptencoding = 'utf-8'
vim.opt.encoding = 'utf-8'

-------------------------------------
--- Misc ----------------------------
-------------------------------------

--- Line Info -----------------------
vim.wo.number = true
vim.wo.relativenumber = true
vim.opt.colorcolumn = '80'

vim.opt.title = true
vim.opt.autoindent = true
vim.opt.hlsearch = true
vim.opt.showcmd = true
vim.opt.laststatus = 2
vim.opt.expandtab = true
vim.opt.scrolloff = 10
vim.opt.shell = 'zsh'
vim.opt.clipboard:append {'unnamedplus'}

--- Tabs ------------------------
-- Define the function
function set_tabstop(languages)
    for _, lang in ipairs(languages) do
        local ts = lang.tabstop -- Tabstop value for this language
        local filetypes = lang.filetypes -- List of filetypes for this language

        for _, ft in ipairs(filetypes) do
            local cmd = string.format(
                "autocmd FileType %s setlocal tabstop=%d shiftwidth=%d",
                ft, ts, ts
            )
            vim.cmd(cmd)
        end
    end
end

local languages = {
    {   tabstop = 4,
        filetypes = {
            'python', 'lua', 'conf', 'sh', 'cpp', 'zsh', 'vhdl', 'rust', 'verilog'
        }
    },
    {   tabstop = 2,
        filetypes = {
            'javascript', 'typescript', 'html', 'css', 'typescriptreact',
            'c', 'json', 'javascriptreact', 'asm', 'riscv_asm'
        }
    }
}
set_tabstop(languages)

--- Folds ----------------------
vim.opt.foldmethod = 'indent'
vim.opt.number = true
vim.opt.showmode = true
vim.g.markdown_folding = 1
vim.g.markdown_enable_folding = 1

--- Cursor --------------------------
vim.opt.cursorline = true
vim.opt.guicursor = 'n-v-c:block,i-ci-ve:ver25,r-cr:hor20,o:hor50,a:blinkwait700-blinkoff400-blinkon250-Cursor/lCursor,sm:block-blinkwait175-blinkoff150-blinkon175'

--- Nvim Tree -----------------------
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.opt.termguicolors = true

--- Highlights ----------------------
vim.opt.wildoptions = 'pum'


