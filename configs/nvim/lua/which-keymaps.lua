local wk = require("which-key")

wk.register({
    ["<leader>"] = {
        t = {
            name = "Telescope",
            ["el"] = {"<cmd>Telescope<CR>", "Open Telescope"},
            ["ff"] = { "<cmd>Telescope find_files<cr>", "Find Files" },
        },
        n = {
            name = "Managers",
            -- Nvim Tree Toggle
            ["t"] = {"<cmd>NvimTreeToggle<CR>", "Toggle NvimTree"},
            -- NnnPicker
            ["n"] = {"<cmd>NnnPicker<CR>", "Open NnnPicker"},
            -- Navbuddy
            ["av"] = {"<cmd>Navbuddy<CR>", "Open Navbuddy"},
        }
    },
    -- Debuging keymaps
    --d = {
    --    name = "Debug",
    --    R = { "<cmd>lua require'dap'.run_to_cursor()<cr>", "Run to Cursor" },
    --    E = { "<cmd>lua require'dapui'.eval(vim.fn.input '[Expression] > ')<cr>", "Evaluate Input" },
    --    b = { "<cmd>lua require'dap'.step_back()<cr>", "Step Back" },
    --    c = { "<cmd>lua require'dap'.continue()<cr>", "Continue" },
    --    d = { "<cmd>lua require'dap'.disconnect()<cr>", "Disconnect" },
    --    e = { "<cmd>lua require'dapui'.eval()<cr>", "Evaluate" },
    --    g = { "<cmd>lua require'dap'.session()<cr>", "Get Session" },
    --    h = { "<cmd>lua require'dap.ui.widgets'.hover()<cr>", "Hover Variables" },
    --    S = { "<cmd>lua require'dap.ui.widgets'.scopes()<cr>", "Scopes" },
    --    i = { "<cmd>lua require'dap'.step_into()<cr>", "Step Into" },
    --    o = { "<cmd>lua require'dap'.step_over()<cr>", "Step Over" },
    --    p = { "<cmd>lua require'dap'.pause.toggle()<cr>", "Pause" },
    --    s = { "<cmd>lua require'dap'.continue()<cr>", "Start" },
    --    t = { "<cmd>lua require'dap'.toggle_breakpoint()<cr>", "Toggle Breakpoint" },
    --    x = { "<cmd>lua require'dap'.terminate()<cr>", "Terminate" },
    --    u = { "<cmd>lua require'dap'.step_out()<cr>", "Step Out" },
    --},
})

