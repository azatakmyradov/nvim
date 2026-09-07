-- [[ Basic Autocommands ]]

-- Highlight when yanking (copying) text
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('azatakmyradov-highlight-yank', { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

-- Attach LSP for docker-compose files
vim.api.nvim_create_autocmd({ 'BufRead', 'BufNewFile' }, {
  pattern = '*.yml,*.yaml',
  callback = function()
    local filename = vim.fn.expand '%:t'
    if string.match(string.lower(filename), 'docker%-compose.*%.ya?ml$') then
      vim.bo.filetype = 'yaml.docker-compose'
    end
  end,
})
