-- Buffer-local LSP keymaps. Registered via LspAttach rather than a per-server
-- on_attach, since nvim-lspconfig's own configs (e.g. basedpyright) define
-- on_attach and would replace ours.
local function on_attach(client, bufnr)
    print("LSP client attached: " .. client.name .. " to buffer: " .. bufnr)
    local opts = { noremap = true, silent = true, buffer = bufnr }

    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
    vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
    vim.keymap.set("i", "<C-s>", vim.lsp.buf.signature_help, opts)

    -- Diagnostics and references in trouble.nvim (v3 modes).
    vim.keymap.set("n", "<leader>vws", "<cmd>Trouble diagnostics toggle<cr>", opts)
    vim.keymap.set("n", "<leader>vd", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", opts)
    vim.keymap.set("n", "<leader>vrr", "<cmd>Trouble lsp_references toggle<cr>", opts)
    -- trouble v3 has no code-action mode.
    vim.keymap.set("n", "<leader>vca", vim.lsp.buf.code_action, opts)

    vim.keymap.set("n", "<leader>gn", function() vim.diagnostic.jump({ count = 1, float = true }) end, opts)
    vim.keymap.set("n", "<leader>gp", function() vim.diagnostic.jump({ count = -1, float = true }) end, opts)

    if client.name == 'ruff' then
        vim.keymap.set("n", "<leader>fm", function()
            vim.lsp.buf.format({ async = true })
        end, opts)
    end
end

return {
    {
        'neovim/nvim-lspconfig',
        -- Provides the per-server defaults under lsp/; servers are configured
        -- with vim.lsp.config() and enabled by mason-lspconfig below.
        event = { "BufReadPre", "BufNewFile" },
        dependencies = {
            'williamboman/mason.nvim',
            'hrsh7th/cmp-nvim-lsp', -- For capabilities
            'folke/trouble.nvim',   -- Used by the LSP keymaps
        },
        config = function()
            vim.diagnostic.config({
                virtual_text = true,
            })

            vim.api.nvim_create_autocmd("LspAttach", {
                group = vim.api.nvim_create_augroup("user_lsp_attach", { clear = true }),
                callback = function(args)
                    local client = vim.lsp.get_client_by_id(args.data.client_id)
                    if client then
                        on_attach(client, args.buf)
                    end
                end,
            })

            vim.lsp.config('*', {
                capabilities = require('cmp_nvim_lsp').default_capabilities(),
            })
            vim.lsp.config('vtsls', {
                filetypes = { "javascript", "javascriptreact", "javascript.jsx", "typescript", "typescriptreact", "typescript.tsx" },
            })
            vim.lsp.config('lua_ls', {
                settings = {
                    Lua = {
                        diagnostics = {
                            globals = { "vim" }
                        }
                    }
                },
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
        -- v2: installs the servers and vim.lsp.enable()s them (automatic_enable).
        -- Loaded on BufReadPre, not VeryLazy, so the servers are enabled before
        -- the first file's FileType event and attach to it.
        event = { "BufReadPre", "BufNewFile" },
        dependencies = { 'williamboman/mason.nvim', 'neovim/nvim-lspconfig' },
        config = function()
            require('mason-lspconfig').setup({
                ensure_installed = { "basedpyright", "ruff", "lua_ls", "vtsls" },
            })
        end
    },

    {
        'folke/trouble.nvim',
        cmd = "Trouble",
        opts = {},
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
