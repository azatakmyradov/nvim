local checkout = vim.fn.expand '~/personal/x3-toolkitv2'

return {
  {
    name = 'x3.nvim',
    url = 'git@github.com:azatakmyradov/x3-toolkitv2.git',
    dir = vim.fn.isdirectory(checkout .. '/editors/nvim') == 1 and checkout or nil,
    lazy = false,
    dependencies = { 'mfussenegger/nvim-dap' },
    opts = {
      remote = {
        locks = true,
        upload_on_save = true,
      },
    },
    config = function(plugin, opts)
      -- Lazy clones the repository root; the Neovim plugin is nested inside it.
      local runtime = plugin.dir .. '/editors/nvim'
      vim.opt.rtp:prepend(runtime)
      vim.cmd.source(runtime .. '/plugin/x3.lua')
      require('x3').setup(opts)
    end,
  },
}
