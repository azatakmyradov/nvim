-- LSP Plugins
return {
  {
    -- `lazydev` configures Lua LSP for your Neovim config, runtime and plugins
    -- used for completion, annotations and signatures of Neovim apis
    'folke/lazydev.nvim',
    ft = 'lua',
    opts = {
      library = {
        -- Load luvit types when the `vim.uv` word is found
        { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
      },
    },
  },
  {
    -- Main LSP Configuration
    'neovim/nvim-lspconfig',
    dependencies = {
      -- Automatically install LSPs and related tools to stdpath for Neovim
      -- Mason must be loaded before its dependents so we need to set it up here.
      { 'mason-org/mason.nvim', opts = {} },
      'mason-org/mason-lspconfig.nvim',
      'WhoIsSethDaniel/mason-tool-installer.nvim',

      -- Useful status updates for LSP.
      { 'j-hui/fidget.nvim', opts = {} },

      -- Allows extra capabilities provided by blink.cmp
      'saghen/blink.cmp',
    },
    config = function()
      local highlight_group = vim.api.nvim_create_augroup('dotfiles-lsp-highlight', { clear = true })
      vim.api.nvim_create_autocmd('LspDetach', {
        group = vim.api.nvim_create_augroup('dotfiles-lsp-detach', { clear = true }),
        callback = function(event)
          for _, client in ipairs(vim.lsp.get_clients { bufnr = event.buf }) do
            if client.id ~= event.data.client_id and client:supports_method('textDocument/documentHighlight', event.buf) then
              return
            end
          end
          vim.api.nvim_clear_autocmds { group = highlight_group, buffer = event.buf }
          if vim.api.nvim_buf_is_valid(event.buf) then
            vim.api.nvim_buf_call(event.buf, vim.lsp.buf.clear_references)
          end
        end,
      })
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('dotfiles-lsp-attach', { clear = true }),
        callback = function(event)
          local map = function(keys, func, desc)
            vim.keymap.set('n', keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
          end

          map('gd', require('fzf-lua').lsp_definitions, '[G]oto [D]efinition')
          map('gr', require('fzf-lua').lsp_references, '[G]oto [R]eferences')
          map('gI', require('fzf-lua').lsp_implementations, '[G]oto [I]mplementation')
          map('<leader>D', require('fzf-lua').lsp_typedefs, 'Type [D]efinition')
          map('<leader>ds', require('fzf-lua').lsp_document_symbols, '[D]ocument [S]ymbols')
          -- map('<leader>ws', require('fzf-lua').lsp_workspace_symbols, '[W]orkspace [S]ymbols')
          map('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
          map('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction')
          map('K', vim.lsp.buf.hover, 'Hover Documentation')
          map('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

          -- The following two autocommands are used to highlight references of the
          -- word under your cursor when your cursor rests there for a little while.
          --    See `:help CursorHold` for information about when this is executed
          --
          -- When you move your cursor, the highlights will be cleared (the second autocommand).
          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if client and client:supports_method('textDocument/documentHighlight', event.buf) then
            vim.api.nvim_clear_autocmds { group = highlight_group, buffer = event.buf }
            vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
              buffer = event.buf,
              group = highlight_group,
              callback = vim.lsp.buf.document_highlight,
            })

            vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
              buffer = event.buf,
              group = highlight_group,
              callback = vim.lsp.buf.clear_references,
            })
          end

          -- The following autocommand is used to enable inlay hints in your
          -- code, if the language server you are using supports them
          --
          -- This may be unwanted, since they displace some of your code
          if client and client.server_capabilities.inlayHintProvider and vim.lsp.inlay_hint then
            map('<leader>th', function()
              local filter = { bufnr = event.buf }
              vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled(filter), filter)
            end, '[T]oggle Inlay [H]ints')
          end
        end,
      })

      -- Diagnostic Config
      -- See :help vim.diagnostic.Opts
      vim.diagnostic.config {
        severity_sort = true,
        float = { border = 'rounded', source = 'if_many' },
        underline = { severity = vim.diagnostic.severity.ERROR },
        signs = vim.g.have_nerd_font and {
          text = {
            [vim.diagnostic.severity.ERROR] = '󰅚 ',
            [vim.diagnostic.severity.WARN] = '󰀪 ',
            [vim.diagnostic.severity.INFO] = '󰋽 ',
            [vim.diagnostic.severity.HINT] = '󰌶 ',
          },
        } or {},
        virtual_text = {
          source = 'if_many',
          spacing = 2,
          format = function(diagnostic)
            local diagnostic_message = {
              [vim.diagnostic.severity.ERROR] = diagnostic.message,
              [vim.diagnostic.severity.WARN] = diagnostic.message,
              [vim.diagnostic.severity.INFO] = diagnostic.message,
              [vim.diagnostic.severity.HINT] = diagnostic.message,
            }
            return diagnostic_message[diagnostic.severity]
          end,
        },
      }

      local capabilities = require('blink.cmp').get_lsp_capabilities()

      local function native_typescript(root)
        local tsc = vim.fs.joinpath(root, 'node_modules', '.bin', 'tsc')
        local package = require('azatakmyradov.buffers').read_json(vim.fs.joinpath(root, 'node_modules', 'typescript', 'package.json'))
        local major = package and tonumber((package.version or ''):match '^(%d+)')
        if major and major >= 7 and vim.fn.executable(tsc) == 1 then
          return tsc
        end
        local tsgo = vim.fs.joinpath(root, 'node_modules', '.bin', 'tsgo')
        if vim.fn.executable(tsgo) == 1 then
          return tsgo
        end
      end
      local typescript_root = vim.lsp.config.ts_ls.root_dir

      local servers = {
        intelephense = {},
        laravel_lsp = {
          cmd = { 'laravel-lsp' },
          filetypes = { 'php', 'blade' },
          root_dir = function(bufnr, on_dir)
            local root = vim.fs.root(bufnr, 'artisan')
            if root then
              on_dir(root)
            end
          end,
        },
        tailwindcss = {},
        gopls = {},
        rust_analyzer = {},
        -- TypeScript 7 ships the native language server as `tsc --lsp`.
        -- Prefer the workspace version so editor diagnostics match the project.
        tsgo = {
          root_dir = function(bufnr, on_dir)
            typescript_root(bufnr, function(root)
              if native_typescript(root) then
                on_dir(root)
              end
            end)
          end,
          cmd = function(dispatchers, config)
            local root_dir = (config or {}).root_dir or vim.fn.getcwd()
            return vim.lsp.rpc.start({ assert(native_typescript(root_dir), 'No workspace native TypeScript compiler'), '--lsp', '--stdio' }, dispatchers)
          end,
        },
        ts_ls = {
          root_dir = function(bufnr, on_dir)
            typescript_root(bufnr, function(root)
              if not native_typescript(root) then
                on_dir(root)
              end
            end)
          end,
        },
        lua_ls = {
          settings = {
            Lua = {
              completion = {
                callSnippet = 'Replace',
              },
            },
          },
        },
        bashls = {},
        svelte = {},
      }

      -- tsgo is supplied by each TypeScript 7 workspace, and Laravel LSP by Composer.
      local ensure_installed = vim.tbl_filter(function(server_name)
        return server_name ~= 'tsgo' and server_name ~= 'laravel_lsp'
      end, vim.tbl_keys(servers or {}))
      vim.list_extend(ensure_installed, {
        'stylua', -- Used to format Lua code
        'blade-formatter',
        'php-cs-fixer',
        'pint',
        'prettier',
        'oxfmt',
        'rustywind',
        'golangci-lint',
      })
      require('mason-tool-installer').setup { ensure_installed = ensure_installed }

      require('mason-lspconfig').setup {
        ensure_installed = {}, -- explicitly set to an empty table (Kickstart populates installs via mason-tool-installer)
        -- Do not start stale servers just because they remain installed in Mason.
        automatic_enable = false,
      }

      for server_name, server in pairs(servers) do
        server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {})
        vim.lsp.config(server_name, server)
        vim.lsp.enable(server_name)
      end
    end,
  },
}
