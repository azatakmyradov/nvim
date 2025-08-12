return { -- Autoformat
  'stevearc/conform.nvim',
  event = { 'BufWritePre' },
  cmd = { 'ConformInfo' },
  opts = {
    notify_on_error = false,
    format_on_save = function(bufnr)
      local disable_filetypes = { c = true, cpp = true }
      if disable_filetypes[vim.bo[bufnr].filetype] then
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
      typescript = { 'prettier', 'rustywind' },
      javascript = { 'prettier', 'rustywind' },
      typescriptreact = { 'prettier', 'rustywind' },
      javascriptreact = { 'prettier', 'rustywind' },
      svelte = { 'prettier', 'rustywind' },
      blade = { 'blade-formatter', 'rustywind' },
      php = { 'pint', 'php_cs_fixer' },
    },
  },
}
