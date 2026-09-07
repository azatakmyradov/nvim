local M = {}

function M.is_large(buf)
  local lines = vim.api.nvim_buf_line_count(buf)
  return lines > 20000 or vim.api.nvim_buf_get_offset(buf, lines) > 1024 * 1024
end

function M.read_json(path)
  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok then
    return nil
  end
  local decoded, value = pcall(vim.json.decode, table.concat(lines, '\n'))
  return decoded and type(value) == 'table' and value or nil
end

function M.uses_tailwind(buf)
  local path = vim.api.nvim_buf_get_name(buf)
  if path == '' then
    return false
  end
  for dir in vim.fs.parents(path) do
    for _, name in ipairs { 'tailwind.config.js', 'tailwind.config.cjs', 'tailwind.config.mjs', 'tailwind.config.ts' } do
      if vim.uv.fs_stat(vim.fs.joinpath(dir, name)) then
        return true
      end
    end
    local package = M.read_json(vim.fs.joinpath(dir, 'package.json'))
    if package and ((package.dependencies or {}).tailwindcss or (package.devDependencies or {}).tailwindcss) then
      return true
    end
    if vim.uv.fs_stat(vim.fs.joinpath(dir, '.git')) then
      break
    end
  end
  return false
end

return M
