local parsers = {
  'bash',
  'c',
  'css',
  'diff',
  'dockerfile',
  'git_config',
  'git_rebase',
  'gitattributes',
  'gitcommit',
  'gitignore',
  'go',
  'gomod',
  'gosum',
  'gowork',
  'html',
  'javascript',
  'jsdoc',
  'json',
  'lua',
  'luadoc',
  'luap',
  'markdown',
  'markdown_inline',
  'php',
  'printf',
  'python',
  'query',
  'regex',
  'toml',
  'tsx',
  'typescript',
  'vim',
  'vimdoc',
  'xml',
  'yaml',
}

local function has_query(lang, query)
  local ok, parsed_query = pcall(vim.treesitter.query.get, lang, query)
  return ok and parsed_query ~= nil
end

local function start_treesitter(buf, opts)
  if require('azatakmyradov.buffers').is_large(buf) then
    vim.treesitter.stop(buf)
    vim.bo[buf].indentexpr = ''
    return
  end
  local ft = vim.bo[buf].filetype
  local lang = vim.treesitter.language.get_lang(ft)

  if not lang then
    return
  end

  if opts.highlight.enable and has_query(lang, 'highlights') then
    pcall(vim.treesitter.start, buf, lang)
  end

  if opts.indent.enable and has_query(lang, 'indents') then
    vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end
end

local function configure_folds(buf, opts)
  local lang = vim.treesitter.language.get_lang(vim.bo[buf].filetype)
  local enabled = opts.folds.enable and not require('azatakmyradov.buffers').is_large(buf) and lang and has_query(lang, 'folds')
  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    vim.wo[win].foldmethod = enabled and 'expr' or 'manual'
    vim.wo[win].foldexpr = enabled and 'v:lua.vim.treesitter.foldexpr()' or '0'
  end
end

return {
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    version = false,
    build = ':TSUpdate',
    lazy = false,
    opts = {
      install_dir = vim.fn.stdpath 'data' .. '/site',
      ensure_installed = parsers,
      highlight = { enable = true },
      indent = { enable = true },
      folds = { enable = true },
    },
    config = function(_, opts)
      local ts = require 'nvim-treesitter'

      ts.setup {
        install_dir = opts.install_dir,
      }

      local installed = {}
      for _, lang in ipairs(ts.get_installed()) do
        installed[lang] = true
      end

      local missing = vim.tbl_filter(function(lang)
        return not installed[lang]
      end, opts.ensure_installed)

      if #missing > 0 then
        ts.install(missing, { summary = true })
      end

      vim.api.nvim_create_autocmd('FileType', {
        group = vim.api.nvim_create_augroup('azatakmyradov_treesitter', { clear = true }),
        callback = function(ev)
          start_treesitter(ev.buf, opts)
          configure_folds(ev.buf, opts)
        end,
      })
      vim.api.nvim_create_autocmd('BufWinEnter', {
        group = 'azatakmyradov_treesitter',
        callback = function(ev)
          configure_folds(ev.buf, opts)
        end,
      })
    end,
  },

  {
    'nvim-treesitter/nvim-treesitter-textobjects',
    branch = 'main',
    event = 'VeryLazy',
    opts = {
      move = {
        enable = true,
        set_jumps = true,
      },
    },
    config = function(_, opts)
      require('nvim-treesitter-textobjects').setup(opts)

      local moves = {
        goto_next_start = { [']f'] = '@function.outer', [']c'] = '@class.outer', [']a'] = '@parameter.inner' },
        goto_next_end = { [']F'] = '@function.outer', [']C'] = '@class.outer', [']A'] = '@parameter.inner' },
        goto_previous_start = { ['[f'] = '@function.outer', ['[c'] = '@class.outer', ['[a'] = '@parameter.inner' },
        goto_previous_end = { ['[F'] = '@function.outer', ['[C'] = '@class.outer', ['[A'] = '@parameter.inner' },
      }

      local function attach(buf)
        if require('azatakmyradov.buffers').is_large(buf) then
          return
        end
        local ft = vim.bo[buf].filetype
        local lang = vim.treesitter.language.get_lang(ft)

        if not opts.move.enable or not lang or not has_query(lang, 'textobjects') then
          return
        end

        for method, keymaps in pairs(moves) do
          for key, query in pairs(keymaps) do
            vim.keymap.set({ 'n', 'x', 'o' }, key, function()
              if vim.wo.diff and key:find '[cC]' then
                return vim.cmd('normal! ' .. key)
              end

              require('nvim-treesitter-textobjects.move')[method](query, 'textobjects')
            end, {
              buffer = buf,
              desc = (key:sub(1, 1) == '[' and 'Prev' or 'Next') .. ' Tree-sitter Object',
              silent = true,
            })
          end
        end
      end

      vim.api.nvim_create_autocmd('FileType', {
        group = vim.api.nvim_create_augroup('azatakmyradov_treesitter_textobjects', { clear = true }),
        callback = function(ev)
          attach(ev.buf)
        end,
      })
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(buf) then
          attach(buf)
        end
      end
    end,
  },

  {
    'windwp/nvim-ts-autotag',
    event = { 'BufReadPost', 'BufNewFile' },
    opts = {},
  },
}
