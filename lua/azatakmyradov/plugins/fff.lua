return {
  {
    'dmtrKovalenko/fff.nvim',
    build = function()
      require('fff.download').download_or_build_binary()
    end,
    lazy = false,
    opts = {
      debug = {
        enabled = false,
        show_scores = false,
      },
    },
    keys = {
      { '<leader>f', function() require('fff').find_files() end, desc = 'Find files' },
      { '<leader>sg', function() require('fff').live_grep() end, desc = 'Live grep' },
      {
        '<leader>G',
        function()
          require('fff').live_grep { grep = { modes = { 'regex', 'plain', 'fuzzy' } } }
        end,
        desc = 'Grep project',
      },
      {
        '<leader>sw',
        function()
          require('fff').live_grep { query = vim.fn.expand '<cword>' }
        end,
        desc = 'Search word',
      },
    },
  },
}
