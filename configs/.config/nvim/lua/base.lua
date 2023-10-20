local vim = vim

-- File encoding
vim.scriptencoding = 'utf-8'
vim.opt.encoding = 'utf-8'
-- vim.opt.fileencofing = 'utf-8'
-- vim.opt.background_opacity = 0.92

-------------------------------------
--- Misc ----------------------------
-------------------------------------

--- Line Info -----------------------
vim.wo.number = true
vim.wo.relativenumber = true

vim.opt.title = true
vim.opt.autoindent = true
vim.opt.hlsearch = true
vim.opt.showcmd = true
vim.opt.cmdheight = 1
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
            local cmd = string.format("autocmd FileType %s setlocal tabstop=%d shiftwidth=%d", ft, ts, ts)
            vim.cmd(cmd)
        end
    end
end

-- Example usage
local languages = {
    {   tabstop = 4,
        filetypes = {'python', 'lua', 'conf', 'sh', 'cpp', 'zsh', 'vhdl'}
    },
    {   tabstop = 2,
        filetypes = { 'javascript', 'typescript', 'html', 'css', 'typescriptreact', 'c', 'json'}
    }
}

set_tabstop(languages)

---vim.cmd('autocmd FileType python setlocal tabstop=4 shiftwidth=4')
---vim.cmd('autocmd FileType lua setlocal tabstop=4 shiftwidth=4')
---vim.cmd('autocmd FileType javascript setlocal tabstop=2 shiftwidth=2')
---vim.cmd('autocmd FileType typescript setlocal tabstop=2 shiftwidth=2')
---vim.cmd('autocmd FileType typescriptreact setlocal tabstop=2 shiftwidth=2')
---vim.cmd('autocmd FileType html setlocal tabstop=2 shiftwidth=2')
---vim.cmd('autocmd FileType css setlocal tabstop=2 shiftwidth=2')
---vim.cmd('autocmd FileType c setlocal tabstop=2 shiftwidth=2')
---vim.cmd('autocmd FileType cpp setlocal tabstop=2 shiftwidth=2')

--- Folds ----------------------
vim.opt.foldmethod = 'indent'
vim.opt.number = true
vim.opt.showmode = true

--- Cursor --------------------------
vim.opt.cursorline = true
vim.opt.guicursor = 'n-v-c:block,i-ci-ve:ver25,r-cr:hor20,o:hor50,a:blinkwait700-blinkoff400-blinkon250-Cursor/lCursor,sm:block-blinkwait175-blinkoff150-blinkon175'
--- vim.cmd [[highlight CursorLine gui=underline guisp=#1C376F]]

--highlight Cursor guifg=white guibg=black
--highlight iCursor guifg=white guibg=steelblue
--set guicursor=n-v-c:block-Cursor
--set guicursor+=i:ver100-iCursor
--set guicursor+=n-v-c:blinkon0
--set guicursor+=i:blinkwait10

--- Nvim Tree -----------------------
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.opt.termguicolors = true

--- Highlights ----------------------
vim.opt.wildoptions = 'pum'

--- Theme ---------------------------
    --local fm = require 'fluoromachine'
    --fm.setup {
    --    glow = false,
    --    theme = 'retrowave',
    --    transparent = false,
    --    overrides = {
    --        ['@type'] = { italic = true, bold = false },
    --        ['@function'] = { italic = false, bold = false },
    --        ['@comment'] = { italic = true , bold = false},
    --        ['@keyword'] = { italic = false , bold= false},
    --        ['@constant'] = { italic = false, bold = false },
    --        ['@variable'] = { italic = true , bold= false},
    --        ['@field'] = { italic = true , bold= false},
    --        ['@parameter'] = { italic = true , bold= false},
    --    },
    --    colors = function(_, d)
    --        return {
    --            bg = '#190920',
    --            alt_bg = d('#190920', 20),
    --            cyan = '#49eaff',
    --            red = '#ff1e34',
    --            yellow = '#ffe756',
    --            comment = '#57ff00', 
    --            orange = '#f38e21',
    --            pink = '#ffadff',
    --            purple = '#9544f7',
    --        }
    --    end,
    --
    --}
    --
    --vim.cmd.colorscheme('fluoromachine')
