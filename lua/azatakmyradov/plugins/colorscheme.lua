return {
  { -- You can easily change to a different colorscheme.
    'catppuccin/nvim',
    name = 'catppuccin',
    priority = 1000, -- Make sure to load this before all the other start plugins.
    config = function()
      require('catppuccin').setup {
        flavour = 'auto',
        background = {
          light = 'latte',
          dark = 'mocha',
        },
      }
      vim.api.nvim_create_autocmd('VimEnter', {
        once = true,
        callback = function()
          vim.cmd.colorscheme 'catppuccin'
        end,
      })
    end,
  },
}
