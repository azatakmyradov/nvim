local hide_gitignored_dirs = true

local function parse_gitignored_dirs(proc)
  local result = proc:wait()
  local ret = {}
  if result.code ~= 0 then
    return ret
  end

  for line in vim.gsplit(result.stdout, '\n', { plain = true, trimempty = true }) do
    if line:sub(-1) == '/' then
      ret[line:sub(1, -2)] = true
    end
  end

  return ret
end

local function new_gitignored_dir_cache()
  return setmetatable({}, {
    __index = function(self, dir)
      local proc = vim.system({ 'git', 'ls-files', '--ignored', '--exclude-standard', '--others', '--directory' }, {
        cwd = dir,
        text = true,
      })
      local ret = parse_gitignored_dirs(proc)
      rawset(self, dir, ret)
      return ret
    end,
  })
end

local gitignored_dirs = new_gitignored_dir_cache()
local refresh_callback_patched = false

local function is_hidden_file(name, bufnr)
  if not hide_gitignored_dirs then
    return false
  end

  local dir = require('oil').get_current_dir(bufnr)
  if not dir then
    return false
  end

  return gitignored_dirs[dir][name] == true
end

local function ensure_refresh_resets_gitignored_cache()
  if refresh_callback_patched then
    return
  end

  local refresh = require('oil.actions').refresh
  local orig_refresh = refresh.callback
  refresh.callback = function(...)
    gitignored_dirs = new_gitignored_dir_cache()
    return orig_refresh(...)
  end
  refresh_callback_patched = true
end

return {
  {
    {
      'stevearc/oil.nvim',
      ---@module 'oil'
      ---@type oil.SetupOpts
      opts = function()
        ensure_refresh_resets_gitignored_cache()

        return {
          keymaps = {
            ['g.'] = false,
            ['<leader>og'] = {
              desc = 'Toggle gitignored dirs',
              mode = 'n',
              callback = function()
                hide_gitignored_dirs = not hide_gitignored_dirs
                require('oil').set_is_hidden_file(is_hidden_file)
              end,
            },
          },
          view_options = {
            show_hidden = false,
            is_hidden_file = is_hidden_file,
          },
        }
      end,
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

    -- Tailwind Tools
    {
      'luckasRanarison/tailwind-tools.nvim',
      name = 'tailwind-tools',
      build = ':UpdateRemotePlugins',
      dependencies = {
        'nvim-telescope/telescope.nvim', -- optional
        'neovim/nvim-lspconfig', -- optional
      },
    },

    { 'stevearc/dressing.nvim' },

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
      { '<leader>F', ":lua require('fzf-lua').files({ no_ignore = true })<CR>" },
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

  { 'folke/neodev.nvim' },

  {
    'andymass/vim-matchup',
    config = function()
      vim.g.matchup_matchparen_enabled = 0
    end,
  },

  { 'github/copilot.vim' },
}
