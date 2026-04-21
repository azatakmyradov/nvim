return {
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'master',
    lazy = false,
    build = ':TSUpdate',
    opts = function()
      local parsers = {
        'bash',
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
        'json',
        'lua',
        'luadoc',
        'markdown',
        'markdown_inline',
        'php',
        'query',
        'regex',
        'toml',
        'tsx',
        'typescript',
        'vim',
        'vimdoc',
        'yaml',
      }

      return {
        parsers = parsers,
        legacy = {
          ensure_installed = parsers,
          auto_install = true,
          highlight = {
            enable = true,
          },
          indent = {
            enable = true,
          },
          autotag = {
            enable = true,
          },
        },
        modern = {
          install_dir = vim.fn.stdpath 'data' .. '/site',
        },
      }
    end,
    config = function(_, opts)
      local has_legacy, legacy = pcall(require, 'nvim-treesitter.configs')
      if has_legacy then
        legacy.setup(opts.legacy)
      else
        local treesitter = require 'nvim-treesitter'
        treesitter.setup(opts.modern)
        treesitter.install(opts.parsers)
      end

      vim.api.nvim_create_autocmd('FileType', {
        pattern = '*',
        callback = function(ev)
          pcall(vim.treesitter.start, ev.buf)
          pcall(function()
            vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end)
        end,
      })
    end,
  },
}
