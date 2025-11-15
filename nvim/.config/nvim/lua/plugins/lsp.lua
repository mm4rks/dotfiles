return {
  {
    'neovim/nvim-lspconfig',
    -- Suggestion 1: Defer loading until a file is opened
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      -- Configure diagnostics
      vim.diagnostic.config({
        virtual_text = true,
      })
    end
  },

  {
    'williamboman/mason.nvim',
    event = "VeryLazy",
    config = function()
      require('mason').setup()
    end
  },
  {
    'williamboman/mason-lspconfig.nvim',
    event = "VeryLazy",
    -- Suggestion 2: Add 'trouble.nvim' as an explicit dependency
    -- (even though it's in ui.lua) because on_attach now uses it.
    dependencies = { 'williamboman/mason.nvim', 'neovim/nvim-lspconfig', 'folke/trouble.nvim' },
    config = function()
      local function on_attach(client, bufnr)
        vim.api.nvim_buf_set_option(bufnr, 'omnunc', 'v:lua.vim.lsp.omnifunc')
        local opts = { noremap = true, silent = true, buffer = bufnr }

        vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
        vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
        vim.keymap.set("n", "<leader>vrn", vim.lsp.buf.rename, opts)
        vim.keymap.set("i", "<C-h>", vim.lsp.buf.signature_help, opts)

        -- Suggestion 2: Integrate 'trouble.nvim' for a better UI
        -- for diagnostics, references, and code actions.
        vim.keymap.set("n", "<leader>vws", function() require("trouble").open("workspace_diagnostics") end, opts)
        vim.keymap.set("n", "<leader>vd", function() require("trouble").open("document_diagnostics") end, opts)
        vim.keymap.set("n", "<leader>vca", function() require("trouble").open("lsp_code_actions") end, opts)
        vim.keymap.set("n", "<leader>vrr", function() require("trouble").open("lsp_references") end, opts)

        -- These diagnostic maps are still useful
        vim.keymap.set("n", "<leader>gn", vim.diagnostic.goto_next, opts)
        vim.keymap.set("n", "<leader>gp", vim.diagnostic.goto_prev, opts)

        if client.name == 'ruff' then
          vim.keymap.set("n", "<leader>fm", function()
            vim.lsp.buf.format({ async = true })
          end, opts)
        end
      end -- This 'end' was missing

      require('mason-lspconfig').setup({
        ensure_installed = { "basedpyright", "ruff", "lua_ls" },
        handlers = {
          -- Default handler for all servers
          function(server_name)
            local lspconfig = require('lspconfig')
            local capabilities = require('cmp_nvim_lsp').default_capabilities()

            local opts = {
              on_attach = on_attach, -- Use the single on_attach function
              capabilities = capabilities
            }

            -- Special settings for lua_ls
            if server_name == "lua_ls" then
              opts.settings = {
                Lua = {
                  diagnostics = { globals = { 'vim' } }
                }
              }
            end

            lspconfig[server_name].setup(opts)
          end,
        }
      })
    end -- This 'end' was missing
  },
  {
    'hrsh7th/nvim-cmp',
    event = "InsertEnter",
    dependencies = {
      'hrsh7th/cmp-buffer',        -- Source for buffer words
      'hrsh7th/cmp-path',          -- Source for file system paths
      'hrsh7th/cmp-nvim-lsp',      -- Source for LSP
      'hrsh7th/cmp-nvim-lua',      -- Source for nvim Lua API
      'saadparwaiz1/cmp_luasnip',
      'L3MON4D3/LuaSnip',
      -- Suggestion 3: Add plugins for icons and command-line completion
      'onsails/lspkind.nvim',
      'hrsh7th/cmp-cmdline',
    },
    config = function()
      local cmp = require('cmp')
      local luasnip = require('luasnip')
      -- Suggestion 3: Require lspkind for icons
      local lspkind = require('lspkind')

      cmp.setup({
        preselect = 'item',
        completion = {
          completeopt = 'menu,menuone,noinsert'
        },
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        -- Suggestion 3: Add formatting block for icons
        formatting = {
          format = lspkind.cmp_format({
            mode = 'symbol',       -- show only symbol
            maxwidth = 50,         -- prevent the popup from becoming too wide
            ellipsis_char = '...', -- characters to use for ellipsis
          })
        },
        window = {
          -- Add borders to completion menu
          completion = cmp.config.window.native(),
          documentation = cmp.config.window.native(),
        },
        mapping = cmp.mapping.preset.insert({
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<C-e>'] = cmp.mapping.abort(), -- This was in your original, but not your new snippet. Keeping it for now.
          ['<CR>'] = cmp.mapping.confirm({ select = false }),
          ['<Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { 'i', 's' }),
          ['<S-Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { 'i', 's' }),
        }),
        -- Suggestion 3: Re-organize sources for priority
        -- and add 'nvim_lua' (which was a dependency but not used)
        sources = cmp.config.sources({
          { name = 'nvim_lsp' },
          { name = 'luasnip', keyword_length = 2 },
          { name = 'nvim_lua' },
        }, {
          { name = 'buffer',  keyword_length = 3 },
          { name = 'path' },
        }),
      })

      -- Suggestion 3: Add command-line completion
      cmp.setup.cmdline({ '/', '?' }, {
        mapping = cmp.mapping.preset.cmdline(),
        sources = {
          { name = 'buffer' }
        }
      })
      cmp.setup.cmdline(':', {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({
          { name = 'path' }
        }, {
          { name = 'cmdline' }
        })
      })
    end
  },
  {
    'L3MON4D3/LuaSnip',
    event = "InsertEnter",
    dependencies = { 'rafamadriz/friendly-snippets' },
    config = function()
      require("luasnip.loaders.from_vscode").lazy_load()
    end
  },
  {
    'rafamadriz/friendly-snippets',
    event = "InsertEnter",
  },
}
