local theme = vim.o.background == 'light' and 'github_light_default' or 'github_dark_default'

require('github-theme').load { theme = theme }
vim.g.colors_name = 'github_system'
