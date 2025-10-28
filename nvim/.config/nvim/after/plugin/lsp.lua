local mason = require('mason')
local cmp = require('cmp')

mason.setup()

-- Setup servers
local servers = { "basedpyright", "ruff", "lua_ls" }
for _, server in ipairs(servers) do
    vim.lsp.config(server, {
        on_attach = function(client, bufnr)
            local opts = { buffer = bufnr, remap = false }

            vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
            vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
            vim.keymap.set("n", "<leader>vws", vim.lsp.buf.workspace_symbol, opts)
            vim.keymap.set("n", "<leader>vd", vim.diagnostic.open_float, opts)
            vim.keymap.set("n", "<leader>gn", vim.diagnostic.goto_next, opts)
            vim.keymap.set("n", "<leader>gp", vim.diagnostic.goto_prev, opts)
            vim.keymap.set("n", "<leader>vca", vim.lsp.buf.code_action, opts)
            vim.keymap.set("n", "<leader>vrr", vim.lsp.buf.references, opts)
            vim.keymap.set("n", "<leader>vrn", vim.lsp.buf.rename, opts)
            vim.keymap.set("i", "<C-h>", vim.lsp.buf.signature_help, opts)

            if client.name == 'ruff' then
                vim.keymap.set("n", "<leader>fm", function()
                    vim.lsp.buf.format({ async = true })
                end, opts)
            end
        end,
        capabilities = require('cmp_nvim_lsp').default_capabilities(),
    })
    vim.lsp.enable(server)
end

-- Configure lua_ls
vim.lsp.config('lua_ls', {
    settings = {
        Lua = {
            diagnostics = {
                globals = { 'vim' }
            }
        }
    }
})


local luasnip = require('luasnip')

cmp.setup({
    preselect = 'item',
    completion = {
        completeopt = 'menu,menuone,noinsert'
    },
    mapping = {
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
        ['<C-Space>'] = cmp.mapping.complete(),
    },
    sources = {
        { name = 'luasnip', keyword_length = 2 },
        { name = 'path' },
        { name = 'buffer',  keyword_length = 3 },
        { name = 'nvim_lsp' },
    }
})


vim.diagnostic.config({
    virtual_text = true,
})