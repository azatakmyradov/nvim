return {
  { -- You can easily change to a different colorscheme.
    'projekt0n/github-nvim-theme',
    name = 'github-theme',
    priority = 1000, -- Make sure to load this before all the other start plugins.
    config = function()
      vim.cmd 'colorscheme github_dark_default'
    end,
  },
}
