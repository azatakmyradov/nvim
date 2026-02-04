return {
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    lazy = false, -- Do not lazy-load
    build = ':TSUpdate', -- Keeps parsers updated
    config = function()
      require('nvim-treesitter').setup {}

      vim.api.nvim_create_autocmd('FileType', {
        pattern = '*',
        callback = function(ev)
          pcall(vim.treesitter.start, ev.buf)
        end,
      })
    end,
  },
}
