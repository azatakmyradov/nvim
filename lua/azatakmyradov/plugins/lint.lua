return {
  { -- Linting
    'mfussenegger/nvim-lint',
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      local lint = require 'lint'
      lint.linters_by_ft = {
        javascript = { 'eslint' },
        javascriptreact = { 'eslint' },
        typescript = { 'eslint' },
        typescriptreact = { 'eslint' },
        php = { 'php', 'phpstan' },
        go = { 'golangcilint' },
      }

      local function executable(name, buf)
        local relative = ({ eslint = 'node_modules/.bin/eslint', phpstan = 'vendor/bin/phpstan' })[name]
        local root = relative and vim.fs.root(buf, relative)
        return root and vim.fs.joinpath(root, relative) or ({ golangcilint = 'golangci-lint' })[name] or name
      end
      for _, name in ipairs { 'eslint', 'phpstan' } do
        lint.linters[name].cmd = function()
          return executable(name, vim.api.nvim_get_current_buf())
        end
      end

      local lint_augroup = vim.api.nvim_create_augroup('lint', { clear = true })
      local function try_lint(buf)
        if not vim.bo[buf].modifiable or vim.bo[buf].buftype ~= '' or require('azatakmyradov.buffers').is_large(buf) then
          return
        end
        local root = vim.fs.root(buf, { 'composer.json', 'go.mod', 'package.json', '.git' })
        local available = {}
        for _, name in ipairs(lint.linters_by_ft[vim.bo[buf].filetype] or {}) do
          if vim.fn.executable(executable(name, buf)) == 1 then
            table.insert(available, name)
          end
        end
        if #available > 0 then
          lint.try_lint(available, { cwd = root })
        end
      end
      vim.api.nvim_create_autocmd('BufWritePost', {
        group = lint_augroup,
        callback = function(ev)
          try_lint(ev.buf)
        end,
      })
      vim.api.nvim_create_user_command('Lint', function()
        try_lint(vim.api.nvim_get_current_buf())
      end, { desc = 'Lint the current buffer' })
    end,
  },
}
