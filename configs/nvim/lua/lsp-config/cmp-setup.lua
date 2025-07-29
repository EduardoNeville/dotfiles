local cmp     = require("cmp")
local luasnip = require("luasnip")

-- Load vscode-style snippets (friendly-snippets)
require("luasnip.loaders.from_vscode").lazy_load()

-- ╭────────────────────────────────────────────────────────────╮
-- │ nvim-cmp                                                  │
-- ╰────────────────────────────────────────────────────────────╯
cmp.setup({
  snippet = {
    expand = function(args) luasnip.lsp_expand(args.body) end,
  },

  mapping = cmp.mapping.preset.insert({
    ["<C-Space>"] = cmp.mapping.complete(),
    ["<CR>"]      = cmp.mapping.confirm({ select = true }),

    ["<Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif luasnip.expand_or_jumpable() then
        luasnip.expand_or_jump()
      else
        fallback()
      end
    end, { "i", "s" }),

    ["<S-Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      elseif luasnip.jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end, { "i", "s" }),
  }),

  sources = cmp.config.sources({
    { name = "nvim_lsp" },
    { name = "luasnip"  },
  }, {
    { name = "path"   },
    { name = "buffer" },
  }),

  formatting = {
    fields = { "kind", "abbr", "menu" },
    format  = function(entry, vim_item)
      vim_item.menu = ({
        nvim_lsp = "[LSP]",
        buffer   = "[Buf]",
        path     = "[Path]",
        luasnip  = "[Snip]",
      })[entry.source.name]
      return vim_item
    end,
  },
})

-- Optional: completion in the search (`/`) and cmdline (`:`) windows
cmp.setup.cmdline("/", {
  mapping = cmp.mapping.preset.cmdline(),
  sources = { { name = "buffer" } },
})
cmp.setup.cmdline(":", {
  mapping = cmp.mapping.preset.cmdline(),
  sources = cmp.config.sources({ { name = "path" } }, { { name = "cmdline" } }),
})

-- Optional: integrate nvim-autopairs so confirmed completion inserts
-- matching brackets/quotes automatically
local cmp_autopairs = require("nvim-autopairs.completion.cmp")
cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
