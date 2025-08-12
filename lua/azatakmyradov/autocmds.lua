-- [[ Basic Autocommands ]]

-- Highlight when yanking (copying) text
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('azatakmyradov-highlight-yank', { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

-- remove trailing space
vim.api.nvim_create_autocmd({ 'BufWritePre' }, {
  group = vim.api.nvim_create_augroup('azatakmyradov-trailing-space', { clear = true }),
  pattern = '*',
  callback = function()
    local position = vim.api.nvim_win_get_cursor(0)
    vim.cmd ':%s/\\s\\+$//e'
    vim.api.nvim_win_set_cursor(0, position)

    -- vim.lsp.buf.format()
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
