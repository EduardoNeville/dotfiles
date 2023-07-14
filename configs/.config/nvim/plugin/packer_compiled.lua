-- Automatically generated packer.nvim plugin loader code

if vim.api.nvim_call_function('has', {'nvim-0.5'}) ~= 1 then
  vim.api.nvim_command('echohl WarningMsg | echom "Invalid Neovim version for packer.nvim! | echohl None"')
  return
end

vim.api.nvim_command('packadd packer.nvim')

local no_errors, error_msg = pcall(function()

_G._packer = _G._packer or {}
_G._packer.inside_compile = true

local time
local profile_info
local should_profile = false
if should_profile then
  local hrtime = vim.loop.hrtime
  profile_info = {}
  time = function(chunk, start)
    if start then
      profile_info[chunk] = hrtime()
    else
      profile_info[chunk] = (hrtime() - profile_info[chunk]) / 1e6
    end
  end
else
  time = function(chunk, start) end
end

local function save_profiles(threshold)
  local sorted_times = {}
  for chunk_name, time_taken in pairs(profile_info) do
    sorted_times[#sorted_times + 1] = {chunk_name, time_taken}
  end
  table.sort(sorted_times, function(a, b) return a[2] > b[2] end)
  local results = {}
  for i, elem in ipairs(sorted_times) do
    if not threshold or threshold and elem[2] > threshold then
      results[i] = elem[1] .. ' took ' .. elem[2] .. 'ms'
    end
  end
  if threshold then
    table.insert(results, '(Only showing plugins that took longer than ' .. threshold .. ' ms ' .. 'to load)')
  end

  _G._packer.profile_output = results
end

time([[Luarocks path setup]], true)
local package_path_str = "/Users/eduardoneville82/.cache/nvim/packer_hererocks/2.1.0-beta3/share/lua/5.1/?.lua;/Users/eduardoneville82/.cache/nvim/packer_hererocks/2.1.0-beta3/share/lua/5.1/?/init.lua;/Users/eduardoneville82/.cache/nvim/packer_hererocks/2.1.0-beta3/lib/luarocks/rocks-5.1/?.lua;/Users/eduardoneville82/.cache/nvim/packer_hererocks/2.1.0-beta3/lib/luarocks/rocks-5.1/?/init.lua"
local install_cpath_pattern = "/Users/eduardoneville82/.cache/nvim/packer_hererocks/2.1.0-beta3/lib/lua/5.1/?.so"
if not string.find(package.path, package_path_str, 1, true) then
  package.path = package.path .. ';' .. package_path_str
end

if not string.find(package.cpath, install_cpath_pattern, 1, true) then
  package.cpath = package.cpath .. ';' .. install_cpath_pattern
end

time([[Luarocks path setup]], false)
time([[try_loadstring definition]], true)
local function try_loadstring(s, component, name)
  local success, result = pcall(loadstring(s), name, _G.packer_plugins[name])
  if not success then
    vim.schedule(function()
      vim.api.nvim_notify('packer.nvim: Error running ' .. component .. ' for ' .. name .. ': ' .. result, vim.log.levels.ERROR, {})
    end)
  end
  return result
end

time([[try_loadstring definition]], false)
time([[Defining packer_plugins]], true)
_G.packer_plugins = {
  ["ChatGPT.nvim"] = {
    config = { "\27LJ\2\n‹\1\0\0\4\0\b\0\v6\0\0\0'\2\1\0B\0\2\0029\0\2\0005\2\4\0005\3\3\0=\3\5\0025\3\6\0=\3\a\2B\0\2\1K\0\1\0\23openai_edit_params\1\0\1\nmodel\ngpt-4\18openai_params\1\0\0\1\0\1\nmodel\ngpt-4\nsetup\fchatgpt\frequire\0" },
    loaded = true,
    path = "/Users/eduardoneville82/.local/share/nvim/site/pack/packer/start/ChatGPT.nvim",
    url = "https://github.com/jackMort/ChatGPT.nvim"
  },
  ["Comment.nvim"] = {
    loaded = true,
    path = "/Users/eduardoneville82/.local/share/nvim/site/pack/packer/start/Comment.nvim",
    url = "https://github.com/numToStr/Comment.nvim"
  },
  ["barbecue.nvim"] = {
    config = { "\27LJ\2\n6\0\0\3\0\3\0\0066\0\0\0'\2\1\0B\0\2\0029\0\2\0B\0\1\1K\0\1\0\nsetup\rbarbecue\frequire\0" },
    loaded = true,
    path = "/Users/eduardoneville82/.local/share/nvim/site/pack/packer/start/barbecue.nvim",
    url = "https://github.com/utilyre/barbecue.nvim"
  },
  ["better-comments.nvim"] = {
    loaded = true,
    path = "/Users/eduardoneville82/.local/share/nvim/site/pack/packer/start/better-comments.nvim",
    url = "https://github.com/Djancyp/better-comments.nvim"
  },
  coq_nvim = {
    loaded = true,
    path = "/Users/eduardoneville82/.local/share/nvim/site/pack/packer/start/coq_nvim",
    url = "https://github.com/ms-jpq/coq_nvim"
  },
  ["flash.nvim"] = {
    config = { "\27LJ\2\n´\4\0\0\18\1\22\0B6\0\0\0'\2\1\0B\0\2\0024\1\6\0005\2\2\0005\3\3\0>\3\2\0026\3\0\0'\5\1\0B\3\2\0029\3\4\3>\3\3\2>\2\1\0015\2\5\0005\3\6\0>\3\2\0026\3\0\0'\5\1\0B\3\2\0029\3\a\3>\3\3\2>\2\2\0015\2\b\0006\3\0\0'\5\1\0B\3\2\0029\3\t\3>\3\3\2>\2\3\0015\2\n\0005\3\v\0>\3\2\0026\3\0\0'\5\1\0B\3\2\0029\3\f\3>\3\3\2>\2\4\0015\2\r\0006\3\0\0'\5\1\0B\3\2\0029\3\14\3>\3\3\2>\2\5\0016\2\15\0\18\4\1\0B\2\2\4X\5\14€6\a\16\0\18\t\6\0B\a\2\5-\v\0\0009\v\17\v9\v\18\v\18\r\b\0\18\14\a\0'\15\19\0\18\16\t\0'\17\20\0&\15\17\0155\16\21\0B\v\5\1E\5\3\3R\5ð\127K\0\1\0\0\0\1\0\2\fnoremap\2\vsilent\2\v()<cr>\14<cmd>lua \20nvim_set_keymap\bapi\vunpack\vipairs\vtoggle\1\5\0\0\14<leader>f\6l\0\24Toggle Flash Search\22treesitter_search\1\3\0\0\6o\6x\1\5\0\0\6R\0\0\28Flash Treesitter Search\vremote\1\5\0\0\6r\6o\0\17Remote Flash\15treesitter\1\4\0\0\6n\6o\6x\1\5\0\0\6S\0\0\21Flash Treesitter\tjump\1\4\0\0\6n\6x\6o\1\5\0\0\6s\0\0\nFlash\nflash\frequire\0" },
    loaded = true,
    path = "/Users/eduardoneville82/.local/share/nvim/site/pack/packer/start/flash.nvim",
    url = "https://github.com/folke/flash.nvim"
  },
  ["fluoromachine.nvim"] = {
    loaded = true,
    path = "/Users/eduardoneville82/.local/share/nvim/site/pack/packer/start/fluoromachine.nvim",
    url = "https://github.com/maxmx03/fluoromachine.nvim"
  },
  ["indent-blankline.nvim"] = {
    config = { "\27LJ\2\nœ\1\0\0\4\0\6\0\t6\0\0\0'\2\1\0B\0\2\0029\0\2\0005\2\4\0005\3\3\0=\3\5\2B\0\2\1K\0\1\0\20buftype_exclude\1\0\2\31show_current_context_start\2\25show_current_context\2\1\2\0\0\rterminal\nsetup\21indent_blankline\frequire\0" },
    loaded = true,
    path = "/Users/eduardoneville82/.local/share/nvim/site/pack/packer/start/indent-blankline.nvim",
    url = "https://github.com/lukas-reineke/indent-blankline.nvim"
  },
  ["lualine.nvim"] = {
    loaded = true,
    path = "/Users/eduardoneville82/.local/share/nvim/site/pack/packer/start/lualine.nvim",
    url = "https://github.com/nvim-lualine/lualine.nvim"
  },
  ["markdown-preview.nvim"] = {
    loaded = true,
    path = "/Users/eduardoneville82/.local/share/nvim/site/pack/packer/start/markdown-preview.nvim",
    url = "https://github.com/iamcco/markdown-preview.nvim"
  },
  ["marks.nvim"] = {
    config = {
      default_mappings = true,
      mappings = {},
      signs = true
    },
    loaded = true,
    path = "/Users/eduardoneville82/.local/share/nvim/site/pack/packer/start/marks.nvim",
    url = "https://github.com/chentoast/marks.nvim"
  },
  ["mason-lspconfig.nvim"] = {
    loaded = true,
    path = "/Users/eduardoneville82/.local/share/nvim/site/pack/packer/start/mason-lspconfig.nvim",
    url = "https://github.com/williamboman/mason-lspconfig.nvim"
  },
  ["mason-null-ls.nvim"] = {
    loaded = true,
    path = "/Users/eduardoneville82/.local/share/nvim/site/pack/packer/start/mason-null-ls.nvim",
    url = "https://github.com/jay-babu/mason-null-ls.nvim"
  },
  ["mason.nvim"] = {
    loaded = true,
    path = "/Users/eduardoneville82/.local/share/nvim/site/pack/packer/start/mason.nvim",
    url = "https://github.com/williamboman/mason.nvim"
  },
  moonfly = {
    loaded = true,
    path = "/Users/eduardoneville82/.local/share/nvim/site/pack/packer/start/moonfly",
    url = "https://github.com/bluz71/vim-moonfly-colors"
  },
  ["nightfox.nvim"] = {
    loaded = true,
    path = "/Users/eduardoneville82/.local/share/nvim/site/pack/packer/start/nightfox.nvim",
    url = "https://github.com/EdenEast/nightfox.nvim"
  },
  ["nnn.nvim"] = {
    config = { "\27LJ\2\n1\0\0\3\0\3\0\0066\0\0\0'\2\1\0B\0\2\0029\0\2\0B\0\1\1K\0\1\0\nsetup\bnnn\frequire\0" },
    loaded = true,
    path = "/Users/eduardoneville82/.local/share/nvim/site/pack/packer/start/nnn.nvim",
    url = "https://github.com/luukvbaal/nnn.nvim"
  },
  ["nui.nvim"] = {
    loaded = true,
    path = "/Users/eduardoneville82/.local/share/nvim/site/pack/packer/start/nui.nvim",
    url = "https://github.com/MunifTanjim/nui.nvim"
  },
  ["null-ls.nvim"] = {
    loaded = true,
    path = "/Users/eduardoneville82/.local/share/nvim/site/pack/packer/start/null-ls.nvim",
    url = "https://github.com/jose-elias-alvarez/null-ls.nvim"
  },
  ["nvim-colorizer.lua"] = {
    config = { "\27LJ\2\n;\0\0\3\0\3\0\a6\0\0\0'\2\1\0B\0\2\0029\0\2\0004\2\0\0B\0\2\1K\0\1\0\nsetup\14colorizer\frequire\0" },
    loaded = true,
    path = "/Users/eduardoneville82/.local/share/nvim/site/pack/packer/start/nvim-colorizer.lua",
    url = "https://github.com/norcalli/nvim-colorizer.lua"
  },
  ["nvim-lspconfig"] = {
    loaded = true,
    path = "/Users/eduardoneville82/.local/share/nvim/site/pack/packer/start/nvim-lspconfig",
    url = "https://github.com/neovim/nvim-lspconfig"
  },
  ["nvim-metals"] = {
    loaded = true,
    path = "/Users/eduardoneville82/.local/share/nvim/site/pack/packer/start/nvim-metals",
    url = "https://github.com/scalameta/nvim-metals"
  },
  ["nvim-navbuddy"] = {
    loaded = true,
    path = "/Users/eduardoneville82/.local/share/nvim/site/pack/packer/start/nvim-navbuddy",
    url = "https://github.com/SmiteshP/nvim-navbuddy"
  },
  ["nvim-navic"] = {
    loaded = true,
    path = "/Users/eduardoneville82/.local/share/nvim/site/pack/packer/start/nvim-navic",
    url = "https://github.com/SmiteshP/nvim-navic"
  },
  ["nvim-surround"] = {
    config = { "\27LJ\2\n?\0\0\3\0\3\0\a6\0\0\0'\2\1\0B\0\2\0029\0\2\0004\2\0\0B\0\2\1K\0\1\0\nsetup\18nvim-surround\frequire\0" },
    loaded = true,
    path = "/Users/eduardoneville82/.local/share/nvim/site/pack/packer/start/nvim-surround",
    url = "https://github.com/kylechui/nvim-surround"
  },
  ["nvim-tree.lua"] = {
    config = { "\27LJ\2\n;\0\0\3\0\3\0\a6\0\0\0'\2\1\0B\0\2\0029\0\2\0004\2\0\0B\0\2\1K\0\1\0\nsetup\14nvim-tree\frequire\0" },
    loaded = true,
    path = "/Users/eduardoneville82/.local/share/nvim/site/pack/packer/start/nvim-tree.lua",
    url = "https://github.com/nvim-tree/nvim-tree.lua"
  },
  ["nvim-treesitter"] = {
    loaded = true,
    path = "/Users/eduardoneville82/.local/share/nvim/site/pack/packer/start/nvim-treesitter",
    url = "https://github.com/nvim-treesitter/nvim-treesitter"
  },
  ["nvim-treesitter-context"] = {
    loaded = true,
    path = "/Users/eduardoneville82/.local/share/nvim/site/pack/packer/start/nvim-treesitter-context",
    url = "https://github.com/nvim-treesitter/nvim-treesitter-context"
  },
  ["nvim-web-devicons"] = {
    loaded = true,
    path = "/Users/eduardoneville82/.local/share/nvim/site/pack/packer/start/nvim-web-devicons",
    url = "https://github.com/kyazdani42/nvim-web-devicons"
  },
  ["packer.nvim"] = {
    loaded = true,
    path = "/Users/eduardoneville82/.local/share/nvim/site/pack/packer/start/packer.nvim",
    url = "https://github.com/wbthomason/packer.nvim"
  },
  ["plenary.nvim"] = {
    loaded = true,
    path = "/Users/eduardoneville82/.local/share/nvim/site/pack/packer/start/plenary.nvim",
    url = "https://github.com/nvim-lua/plenary.nvim"
  },
  ["rainbow_csv.nvim"] = {
    config = { "\27LJ\2\n9\0\0\3\0\3\0\0066\0\0\0'\2\1\0B\0\2\0029\0\2\0B\0\1\1K\0\1\0\nsetup\16rainbow_csv\frequire\0" },
    loaded = false,
    needs_bufread = false,
    only_cond = false,
    path = "/Users/eduardoneville82/.local/share/nvim/site/pack/packer/opt/rainbow_csv.nvim",
    url = "https://github.com/cameron-wags/rainbow_csv.nvim"
  },
  ripgrep = {
    loaded = true,
    path = "/Users/eduardoneville82/.local/share/nvim/site/pack/packer/start/ripgrep",
    url = "https://github.com/BurntSushi/ripgrep"
  },
  ["sqls.nvim"] = {
    loaded = true,
    path = "/Users/eduardoneville82/.local/share/nvim/site/pack/packer/start/sqls.nvim",
    url = "https://github.com/nanotee/sqls.nvim"
  },
  ["telescope.nvim"] = {
    loaded = true,
    path = "/Users/eduardoneville82/.local/share/nvim/site/pack/packer/start/telescope.nvim",
    url = "https://github.com/nvim-telescope/telescope.nvim"
  },
  ["tmux.nvim"] = {
    config = { "\27LJ\2\n.\0\0\3\0\3\0\0056\0\0\0'\2\1\0B\0\2\0029\0\2\0D\0\1\0\nsetup\ttmux\frequire\0" },
    loaded = true,
    path = "/Users/eduardoneville82/.local/share/nvim/site/pack/packer/start/tmux.nvim",
    url = "https://github.com/aserowy/tmux.nvim"
  },
  ["tokyonight.nvim"] = {
    loaded = true,
    path = "/Users/eduardoneville82/.local/share/nvim/site/pack/packer/start/tokyonight.nvim",
    url = "https://github.com/folke/tokyonight.nvim"
  },
  ["transparent.nvim"] = {
    loaded = true,
    path = "/Users/eduardoneville82/.local/share/nvim/site/pack/packer/start/transparent.nvim",
    url = "https://github.com/xiyaowong/transparent.nvim"
  },
  ["vim-farout"] = {
    loaded = true,
    path = "/Users/eduardoneville82/.local/share/nvim/site/pack/packer/start/vim-farout",
    url = "https://github.com/fcpg/vim-farout"
  }
}

time([[Defining packer_plugins]], false)
local module_lazy_loads = {
  ["^rainbow_csv"] = "rainbow_csv.nvim",
  ["^rainbow_csv%.fns"] = "rainbow_csv.nvim"
}
local lazy_load_called = {['packer.load'] = true}
local function lazy_load_module(module_name)
  local to_load = {}
  if lazy_load_called[module_name] then return nil end
  lazy_load_called[module_name] = true
  for module_pat, plugin_name in pairs(module_lazy_loads) do
    if not _G.packer_plugins[plugin_name].loaded and string.match(module_name, module_pat) then
      to_load[#to_load + 1] = plugin_name
    end
  end

  if #to_load > 0 then
    require('packer.load')(to_load, {module = module_name}, _G.packer_plugins)
    local loaded_mod = package.loaded[module_name]
    if loaded_mod then
      return function(modname) return loaded_mod end
    end
  end
end

if not vim.g.packer_custom_loader_enabled then
  table.insert(package.loaders, 1, lazy_load_module)
  vim.g.packer_custom_loader_enabled = true
end

-- Config for: tmux.nvim
time([[Config for tmux.nvim]], true)
try_loadstring("\27LJ\2\n.\0\0\3\0\3\0\0056\0\0\0'\2\1\0B\0\2\0029\0\2\0D\0\1\0\nsetup\ttmux\frequire\0", "config", "tmux.nvim")
time([[Config for tmux.nvim]], false)
-- Config for: nvim-tree.lua
time([[Config for nvim-tree.lua]], true)
try_loadstring("\27LJ\2\n;\0\0\3\0\3\0\a6\0\0\0'\2\1\0B\0\2\0029\0\2\0004\2\0\0B\0\2\1K\0\1\0\nsetup\14nvim-tree\frequire\0", "config", "nvim-tree.lua")
time([[Config for nvim-tree.lua]], false)
-- Config for: barbecue.nvim
time([[Config for barbecue.nvim]], true)
try_loadstring("\27LJ\2\n6\0\0\3\0\3\0\0066\0\0\0'\2\1\0B\0\2\0029\0\2\0B\0\1\1K\0\1\0\nsetup\rbarbecue\frequire\0", "config", "barbecue.nvim")
time([[Config for barbecue.nvim]], false)
-- Config for: nnn.nvim
time([[Config for nnn.nvim]], true)
try_loadstring("\27LJ\2\n1\0\0\3\0\3\0\0066\0\0\0'\2\1\0B\0\2\0029\0\2\0B\0\1\1K\0\1\0\nsetup\bnnn\frequire\0", "config", "nnn.nvim")
time([[Config for nnn.nvim]], false)
-- Config for: marks.nvim
time([[Config for marks.nvim]], true)
time([[Config for marks.nvim]], false)
-- Config for: indent-blankline.nvim
time([[Config for indent-blankline.nvim]], true)
try_loadstring("\27LJ\2\nœ\1\0\0\4\0\6\0\t6\0\0\0'\2\1\0B\0\2\0029\0\2\0005\2\4\0005\3\3\0=\3\5\2B\0\2\1K\0\1\0\20buftype_exclude\1\0\2\31show_current_context_start\2\25show_current_context\2\1\2\0\0\rterminal\nsetup\21indent_blankline\frequire\0", "config", "indent-blankline.nvim")
time([[Config for indent-blankline.nvim]], false)
-- Config for: nvim-surround
time([[Config for nvim-surround]], true)
try_loadstring("\27LJ\2\n?\0\0\3\0\3\0\a6\0\0\0'\2\1\0B\0\2\0029\0\2\0004\2\0\0B\0\2\1K\0\1\0\nsetup\18nvim-surround\frequire\0", "config", "nvim-surround")
time([[Config for nvim-surround]], false)
-- Config for: flash.nvim
time([[Config for flash.nvim]], true)
try_loadstring("\27LJ\2\n´\4\0\0\18\1\22\0B6\0\0\0'\2\1\0B\0\2\0024\1\6\0005\2\2\0005\3\3\0>\3\2\0026\3\0\0'\5\1\0B\3\2\0029\3\4\3>\3\3\2>\2\1\0015\2\5\0005\3\6\0>\3\2\0026\3\0\0'\5\1\0B\3\2\0029\3\a\3>\3\3\2>\2\2\0015\2\b\0006\3\0\0'\5\1\0B\3\2\0029\3\t\3>\3\3\2>\2\3\0015\2\n\0005\3\v\0>\3\2\0026\3\0\0'\5\1\0B\3\2\0029\3\f\3>\3\3\2>\2\4\0015\2\r\0006\3\0\0'\5\1\0B\3\2\0029\3\14\3>\3\3\2>\2\5\0016\2\15\0\18\4\1\0B\2\2\4X\5\14€6\a\16\0\18\t\6\0B\a\2\5-\v\0\0009\v\17\v9\v\18\v\18\r\b\0\18\14\a\0'\15\19\0\18\16\t\0'\17\20\0&\15\17\0155\16\21\0B\v\5\1E\5\3\3R\5ð\127K\0\1\0\0\0\1\0\2\fnoremap\2\vsilent\2\v()<cr>\14<cmd>lua \20nvim_set_keymap\bapi\vunpack\vipairs\vtoggle\1\5\0\0\14<leader>f\6l\0\24Toggle Flash Search\22treesitter_search\1\3\0\0\6o\6x\1\5\0\0\6R\0\0\28Flash Treesitter Search\vremote\1\5\0\0\6r\6o\0\17Remote Flash\15treesitter\1\4\0\0\6n\6o\6x\1\5\0\0\6S\0\0\21Flash Treesitter\tjump\1\4\0\0\6n\6x\6o\1\5\0\0\6s\0\0\nFlash\nflash\frequire\0", "config", "flash.nvim")
time([[Config for flash.nvim]], false)
-- Config for: ChatGPT.nvim
time([[Config for ChatGPT.nvim]], true)
try_loadstring("\27LJ\2\n‹\1\0\0\4\0\b\0\v6\0\0\0'\2\1\0B\0\2\0029\0\2\0005\2\4\0005\3\3\0=\3\5\0025\3\6\0=\3\a\2B\0\2\1K\0\1\0\23openai_edit_params\1\0\1\nmodel\ngpt-4\18openai_params\1\0\0\1\0\1\nmodel\ngpt-4\nsetup\fchatgpt\frequire\0", "config", "ChatGPT.nvim")
time([[Config for ChatGPT.nvim]], false)
-- Config for: nvim-colorizer.lua
time([[Config for nvim-colorizer.lua]], true)
try_loadstring("\27LJ\2\n;\0\0\3\0\3\0\a6\0\0\0'\2\1\0B\0\2\0029\0\2\0004\2\0\0B\0\2\1K\0\1\0\nsetup\14colorizer\frequire\0", "config", "nvim-colorizer.lua")
time([[Config for nvim-colorizer.lua]], false)
vim.cmd [[augroup packer_load_aucmds]]
vim.cmd [[au!]]
  -- Filetype lazy-loads
time([[Defining lazy-load filetype autocommands]], true)
vim.cmd [[au FileType csv_pipe ++once lua require("packer.load")({'rainbow_csv.nvim'}, { ft = "csv_pipe" }, _G.packer_plugins)]]
vim.cmd [[au FileType rfc_csv ++once lua require("packer.load")({'rainbow_csv.nvim'}, { ft = "rfc_csv" }, _G.packer_plugins)]]
vim.cmd [[au FileType rfc_semicolon ++once lua require("packer.load")({'rainbow_csv.nvim'}, { ft = "rfc_semicolon" }, _G.packer_plugins)]]
vim.cmd [[au FileType csv ++once lua require("packer.load")({'rainbow_csv.nvim'}, { ft = "csv" }, _G.packer_plugins)]]
vim.cmd [[au FileType tsv ++once lua require("packer.load")({'rainbow_csv.nvim'}, { ft = "tsv" }, _G.packer_plugins)]]
vim.cmd [[au FileType csv_semicolon ++once lua require("packer.load")({'rainbow_csv.nvim'}, { ft = "csv_semicolon" }, _G.packer_plugins)]]
vim.cmd [[au FileType csv_whitespace ++once lua require("packer.load")({'rainbow_csv.nvim'}, { ft = "csv_whitespace" }, _G.packer_plugins)]]
time([[Defining lazy-load filetype autocommands]], false)
vim.cmd("augroup END")

_G._packer.inside_compile = false
if _G._packer.needs_bufread == true then
  vim.cmd("doautocmd BufRead")
end
_G._packer.needs_bufread = false

if should_profile then save_profiles() end

end)

if not no_errors then
  error_msg = error_msg:gsub('"', '\\"')
  vim.api.nvim_command('echohl ErrorMsg | echom "Error in packer_compiled: '..error_msg..'" | echom "Please check your config for correctness" | echohl None')
end
