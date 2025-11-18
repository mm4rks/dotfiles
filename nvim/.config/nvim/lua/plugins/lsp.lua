local function on_attach(client, bufnr)
    print("LSP client attached: " .. client.name .. " to buffer: " .. bufnr)
    vim.api.nvim_buf_set_option(bufnr, 'omnunc', 'v:lua.vim.lsp.omnifunc')
    local opts = { noremap = true, silent = true, buffer = bufnr }

    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
    vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
    vim.keymap.set("n", "<leader>vrn", vim.lsp.buf.rename, opts)
    vim.keymap.set("i", "<C-s>", vim.lsp.buf.signature_help, opts)

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
end

return {
    {
        'neovim/nvim-lspconfig',
        -- This plugin is now primarily a dependency.
        -- We still configure diagnostics here.
        event = { "BufReadPre", "BufNewFile" },
        dependencies = {
            'williamboman/mason.nvim',
            'hrsh7th/cmp-nvim-lsp', -- For capabilities
            'folke/trouble.nvim',   -- Used in on_attach
        },
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
        -- This plugin now contains all the setup logic
        event = "VeryLazy",
        dependencies = { 'williamboman/mason.nvim', 'neovim/nvim-lspconfig' },
        config = function()
            -- These must be defined INSIDE the config function
            -- to be in scope for the handlers.
            local lspconfig = require('lspconfig')
            local capabilities = require('cmp_nvim_lsp').default_capabilities()

            require('mason-lspconfig').setup({
                ensure_installed = { "basedpyright", "ruff", "lua_ls" },
                -- The 'handlers' table is the correct place for this logic
                handlers = {
                    -- 1. This is the default handler for all servers
                    -- (e.g., ruff, basedpyright)
                    function(server_name)
                        lspconfig[server_name].setup({
                            on_attach = on_attach,
                            capabilities = capabilities
                        })
                    end,
                },
                vim.lsp.config("lua_ls", {
                    settings = {
                        Lua = {
                            diagnostics = {
                                globals = { "vim" } }
                        }
                    }
                })
            })
        end
    },

    {
        'hrsh7th/nvim-cmp',
        event = "InsertEnter",
        dependencies = {
            'hrsh7th/cmp-buffer',   -- Source for buffer words
            'hrsh7th/cmp-path',     -- Source for file system paths
            'hrsh7th/cmp-nvim-lsp', -- Source for LSP
            'hrsh7th/cmp-nvim-lua', -- Source for nvim Lua API
            'saadparwaiz1/cmp_luasnip',
            'L3MON4D3/LuaSnip',
            'hrsh7th/cmp-cmdline',
        },
        config = function()
            local cmp = require('cmp')
            local luasnip = require('luasnip')

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
                window = {
                    completion = cmp.config.window.bordered(),
                    documentation = cmp.config.window.bordered(),
                },
                mapping = cmp.mapping.preset.insert({
                    ['<C-Space>'] = cmp.mapping.complete(),
                    ['<C-e>'] = cmp.mapping.abort(),
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
                sources = cmp.config.sources({
                    { name = 'nvim_lsp' },
                    { name = 'luasnip', keyword_length = 2 },
                    { name = 'nvim_lua' },
                }, {
                    { name = 'buffer', keyword_length = 3 },
                    { name = 'path' },
                }),
            })

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
