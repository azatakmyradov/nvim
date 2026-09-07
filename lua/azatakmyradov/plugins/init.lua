local hide_gitignored_dirs = true

local function parse_gitignored_dirs(result)
  local ret = {}
  if result.code ~= 0 then
    return ret
  end

  for line in vim.gsplit(result.stdout or '', '\0', { plain = true, trimempty = true }) do
    if line:sub(-1) == '/' then
      ret[line:sub(1, -2)] = true
    end
  end

  return ret
end

local gitignored_dirs
local is_hidden_file

local function new_gitignored_dir_cache()
  return setmetatable({}, {
    __index = function(self, dir)
      local pending = {}
      rawset(self, dir, pending)
      vim.system(
        { 'git', 'ls-files', '-z', '--ignored', '--exclude-standard', '--others', '--directory' },
        {
          cwd = dir,
          text = true,
        },
        vim.schedule_wrap(function(result)
          -- A manual refresh may have replaced this cache while Git was running.
          if self ~= gitignored_dirs then
            return
          end
          rawset(self, dir, parse_gitignored_dirs(result))
          for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].filetype == 'oil' and vim.bo[buf].modified then
              return
            end
          end
          require('oil').set_is_hidden_file(is_hidden_file)
        end)
      )
      return pending
    end,
  })
end

gitignored_dirs = new_gitignored_dir_cache()
local refresh_callback_patched = false

is_hidden_file = function(name, bufnr)
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
      cmd = { 'Git', 'G', 'Gdiffsplit', 'Gvdiffsplit', 'Gedit', 'Gread', 'Gwrite' },
      dependencies = {
        'tpope/vim-rhubarb',
      },
    },

    -- Undo Tree
    { 'mbbill/undotree', cmd = 'UndotreeToggle' },

    {
      'folke/snacks.nvim',
      priority = 1000,
      lazy = false,
      opts = { input = { enabled = true }, zen = { enabled = true } },
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
    init = function()
      vim.ui.select = function(...)
        require 'fzf-lua'
        return vim.ui.select(...)
      end
    end,
    config = function(_, opts)
      require('fzf-lua').setup(opts)
      require('fzf-lua').register_ui_select()
    end,
    opts = {
      keymap = { fzf = { ['ctrl-q'] = 'select-all+accept' } },
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

  {
    'andymass/vim-matchup',
    config = function()
      vim.g.matchup_matchparen_enabled = 0
    end,
  },
}
