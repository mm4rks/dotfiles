return {
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
        dependencies = { 'williamboman/mason.nvim', 'neovim/nvim-lspconfig' },
        config = function()
            -- Define on_attach *once*
            local function on_attach(client, bufnr)
                vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')
                local bufopts = { noremap = true, silent = true, buffer = bufnr }
                vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, bufopts)
                vim.keymap.set('n', 'gd', vim.lsp.buf.definition, bufopts)
                vim.keymap.set('n', 'K', vim.lsp.buf.hover, bufopts)
                vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, bufopts)
                vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, bufopts)
                vim.keymap.set('n', '<leader>wa', vim.lsp.buf.add_workspace_folder, bufopts)
                vim.keymap.set('n', '<leader>wr', vim.lsp.buf.remove_workspace_folder, bufopts)
                vim.keymap.set('n', '<leader>wl', function()
                    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
                end, bufopts)
                vim.keymap.set('n', '<leader>D', vim.lsp.buf.type_definition, bufopts)
                vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, bufopts)
                vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, bufopts)
                vim.keymap.set('n', 'gr', vim.lsp.buf.references, bufopts)
                vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, bufopts)
                vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, bufopts)
                vim.keymap.set('n', ']d', vim.diagnostic.goto_next, bufopts)
                vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, bufopts)
            end

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
        end
    },
    'neovim/nvim-lspconfig',
}
