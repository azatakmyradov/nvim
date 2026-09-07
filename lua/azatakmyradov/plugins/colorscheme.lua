return {
  {
    'catppuccin/nvim',
    name = 'catppuccin',
    lazy = false,
    priority = 1000,
    opts = {
      flavour = 'auto',
      background = { light = 'latte', dark = 'mocha' },
    },
    config = function(_, opts)
      require('catppuccin').setup(opts)
      vim.api.nvim_create_autocmd('VimEnter', {
        once = true,
        callback = function()
          vim.cmd.colorscheme 'catppuccin'
        end,
      })
    end,
  },
}
