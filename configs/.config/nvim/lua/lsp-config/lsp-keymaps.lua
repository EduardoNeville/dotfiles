local server_maps = function(opts)
  vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts) -- goto def
  vim.keymap.set("n", "<leader> hg", vim.lsp.buf.hover, opts) -- see docs
  vim.keymap.set("n", "<leader>fo", function() -- format
    vim.lsp.buf.format({ async = true })
  end, opts)
end
