return {
  {
    {
      'stevearc/oil.nvim',
      ---@module 'oil'
      ---@type oil.SetupOpts
      opts = {
        view_options = {
          show_hidden = true,
        },
      },
      -- Optional dependencies
      dependencies = { { 'echasnovski/mini.icons', opts = {} } },
      -- dependencies = { "nvim-tree/nvim-web-devicons" }, -- use if prefer nvim-web-devicons
    },

    -- harpoon to access files quickly
    { 'ThePrimeagen/harpoon' },

    'NMAC427/guess-indent.nvim', -- Detect tabstop and shiftwidth automatically

    { -- Adds git related signs to the gutter, as well as utilities for managing changes
      'lewis6991/gitsigns.nvim',
      opts = {
        signs = {
          add = { text = '+' },
          change = { text = '~' },
          delete = { text = '_' },
          topdelete = { text = '‾' },
          changedelete = { text = '~' },
        },
      },
    },

    -- Highlight todo, notes, etc in comments
    { 'folke/todo-comments.nvim', event = 'VimEnter', dependencies = { 'nvim-lua/plenary.nvim' }, opts = { signs = false } },

    -- Git related plugins
    {
      'tpope/vim-fugitive',
      dependencies = {
        'tpope/vim-rhubarb',
      },
    },

    -- Undo Tree
    { 'mbbill/undotree' },

    -- auto close html tags
    { 'windwp/nvim-ts-autotag' },

    -- Tailwind Tools
    {
      'luckasRanarison/tailwind-tools.nvim',
      name = 'tailwind-tools',
      build = ':UpdateRemotePlugins',
      dependencies = {
        'nvim-treesitter/nvim-treesitter',
        'nvim-telescope/telescope.nvim', -- optional
        'neovim/nvim-lspconfig', -- optional
      },
    },

    { 'stevearc/dressing.nvim' },

    {
      'nvzone/typr',
      dependencies = 'nvzone/volt',
      opts = {},
      cmd = { 'Typr', 'TyprStats' },
    },

    { -- Collection of various small independent plugins/modules
      'echasnovski/mini.nvim',
      config = function()
        -- Better Around/Inside textobjects
        --
        -- Examples:
        --  - va)  - [V]isually select [A]round [)]paren
        --  - yinq - [Y]ank [I]nside [N]ext [']quote
        --  - ci'  - [C]hange [I]nside [']quote
        require('mini.ai').setup { n_lines = 500 }

        -- Add/delete/replace surroundings (brackets, quotes, etc.)
        --
        -- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
        -- - sd'   - [S]urround [D]elete [']quotes
        -- - sr)'  - [S]urround [R]eplace [)] [']
        require('mini.surround').setup()

        -- Simple and easy statusline.
        --  You could remove this setup call if you don't like it,
        --  and try some other statusline plugin
        local statusline = require 'mini.statusline'
        -- set use_icons to true if you have a Nerd Font
        statusline.setup { use_icons = vim.g.have_nerd_font }

        -- You can configure sections in the statusline by overriding their
        -- default behavior. For example, here we set the section for
        -- cursor location to LINE:COLUMN
        ---@diagnostic disable-next-line: duplicate-set-field
        statusline.section_location = function()
          return '%2l:%-2v'
        end
      end,
    },
  },
  {
    'adalessa/laravel.nvim',
    dependencies = {
      'tpope/vim-dotenv',
      'nvim-telescope/telescope.nvim',
      'MunifTanjim/nui.nvim',
      'kevinhwang91/promise-async',
    },
    cmd = { 'Laravel' },
    keys = {
      { '<leader>la', ':Laravel artisan<cr>' },
      { '<leader>lr', ':Laravel routes<cr>' },
      { '<leader>lm', ':Laravel related<cr>' },
    },
    event = { 'VeryLazy' },
    opts = {},
    config = true,
  },
  -- Lua
  {
    {
      'gbprod/phpactor.nvim',
      ft = 'php',
      dependencies = {
        'nvim-lua/plenary.nvim',
        'neovim/nvim-lspconfig',
      },
      opts = {
        lspconfig = {
          enabled = false,
          options = {},
        },
      },
      keys = {
        { '<leader>pm', ':lua require("phpactor").rpc("context_menu", {})<CR>' },
        { '<leader>pn', ':lua require("phpactor").rpc("new_class", {})<CR>' },
      },
    },
  },
  {
    'ibhagwan/fzf-lua',
    -- optional for icon support
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      require('fzf-lua').setup {
        keymap = {
          fzf = {
            ['ctrl-q'] = 'select-all+accept',
          },
        },
      }
    end,
    opts = {
      winopts = {
        preview = {
          hidden = true,
        },
      },
    },
    keys = {
      { '<leader>f', ":lua require('fzf-lua').files()<CR>" },
      { '<leader>F', ":lua require('fzf-lua').files({ no_ignore = true })<CR>" },
      { '<leader>sg', ":lua require('fzf-lua').live_grep_native()<CR>" },
      { '<leader>G', ":lua require('fzf-lua').grep_project()<CR>" },
      { '<leader>sr', ":lua require('fzf-lua').resume()<CR>" },
      { '<leader>ss', ':FzfLua<CR>' },
      { '<leader>sd', ":lua require('fzf-lua').diagnostics_document()<CR>" },
      { '<leader>sb', ":lua require('fzf-lua').buffers()<CR>" },
      { '<leader>/', ":lua require('fzf-lua').grep_curbuf()<CR>" },
      { '<leader>sn', ":lua require('fzf-lua').files({ cwd = vim.fn.stdpath 'config' })<CR>" },
      { '<leader>sh', ":lua require('fzf-lua').helptags()<CR>" },
      { '<leader>sk', ":lua require('fzf-lua').keymaps()<CR>" },
    },
  },
  {
    'afonsofrancof/worktrees.nvim',
    event = 'VeryLazy',
    opts = {
      -- Specify where to create worktrees relative to git common dir
      -- The common dir is the .git dir in a normal repo or the root dir of a bare repo
      base_path = '..', -- Parent directory of common dir

      -- Template for worktree folder names
      -- This is only used if you don't specify the folder name when creating the worktree
      path_template = '{branch}', -- Default: use branch name

      -- Command names (optional)
      commands = {
        create = 'WorktreeCreate',
        delete = 'WorktreeDelete',
        switch = 'WorktreeSwitch',
      },

      -- Key mappings for interactive UI (optional)
      mappings = {
        create = '<leader>wc',
        delete = '<leader>wd',
        switch = '<leader>ws',
      },
    },
  },

  { 'folke/zen-mode.nvim' },
  {
    'andymass/vim-matchup',
    config = function()
      vim.g.matchup_matchparen_enabled = 0
    end,
  },
}
