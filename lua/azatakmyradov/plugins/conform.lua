local function web_formatters(bufnr)
  local conform = require 'conform'
  local formatters = {}

  if vim.bo[bufnr].filetype ~= 'svelte' and conform.get_formatter_info('oxfmt', bufnr).available then
    table.insert(formatters, 'oxfmt')
  elseif conform.get_formatter_info('prettier', bufnr).available then
    table.insert(formatters, 'prettier')
  end

  if require('azatakmyradov.buffers').uses_tailwind(bufnr) then
    table.insert(formatters, 'rustywind')
  end

  return formatters
end

return { -- Autoformat
  'stevearc/conform.nvim',
  event = { 'BufWritePre' },
  cmd = { 'ConformInfo' },
  opts = {
    notify_on_error = false,
    format_on_save = function(bufnr)
      local disable_filetypes = { c = true, cpp = true }
      if disable_filetypes[vim.bo[bufnr].filetype] or require('azatakmyradov.buffers').is_large(bufnr) then
        return nil
      else
        return {
          timeout_ms = 500,
          lsp_format = 'fallback',
        }
      end
    end,
    formatters_by_ft = {
      lua = { 'stylua' },
      typescript = web_formatters,
      javascript = web_formatters,
      typescriptreact = web_formatters,
      javascriptreact = web_formatters,
      svelte = web_formatters,
      blade = function(bufnr)
        return require('azatakmyradov.buffers').uses_tailwind(bufnr) and { 'blade-formatter', 'rustywind' } or { 'blade-formatter' }
      end,
      php = function(bufnr)
        local root = vim.fs.root(bufnr, { 'pint.json', 'artisan', 'vendor/bin/pint' })
        return root and { 'pint' } or { 'php_cs_fixer' }
      end,
      json = { 'oxfmt', 'prettier', stop_after_first = true },
      jsonc = { 'oxfmt', 'prettier', stop_after_first = true },
    },
  },
}
