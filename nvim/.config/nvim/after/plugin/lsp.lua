local lsp = require('lsp-zero')

lsp.preset('recommended')
 -- vim.lsp.set_log_level("debug")

lsp.ensure_installed({
    'pyright',
    'lua_ls',
    'emmet_ls',
})

-- Fix Undefined global 'vim'
lsp.configure('lua_ls', {
    settings = {
        Lua = {
            diagnostics = {
                globals = { 'vim' }
            }
        }
    }
})

lsp.configure('emmet_ls', {
    settings = {
        filetypes = { "css", "eruby", "html", "javascript", "javascriptreact", "less", "sass", "scss", "svelte", "pug",
            "typescriptreact", "vue", "htmldjango" },
        init_options = {
            html = {
                options = {
                    -- For possible options, see: https://github.com/emmetio/emmet/blob/master/src/config.ts#L79-L267
                    ["bem.enabled"] = true,
                },
            },
        }
    }
})

lsp.set_preferences({
    sign_icons = {
        error = 'E',
        warn = 'W',
        hint = 'H',
        info = 'I'
    }
})

lsp.on_attach(function(client, bufnr)
    local opts = { buffer = bufnr, remap = false }

    if client.name == "eslint" then
        vim.cmd.LspStop('eslint')
        return
    end

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
end)




lsp.setup()


local null_ls_ok, null_ls = pcall(require, "null-ls")
if null_ls_ok then
    null_ls.setup({
        sources = {
            -- python
            -- MasonInstall black
            -- MasonInstall isort
            null_ls.builtins.formatting.black.with({
                extra_args = { "--line-length=140" }
            }),
            null_ls.builtins.formatting.isort,
            -- htmldjango
            null_ls.builtins.formatting.djlint,
            null_ls.builtins.diagnostics.djlint,
        }
    })
end

require('luasnip').config.set_config({
    region_check_events = 'InsertEnter',
    delete_check_events = 'InsertLeave'
})

require('luasnip.loaders.from_vscode').lazy_load()


local cmp = require('cmp')
local cmp_action = require('lsp-zero').cmp_action()

cmp.setup({
    preselect = 'item',
    completion = {
        completeopt = 'menu,menuone,noinsert'
    },
    mapping = {
        ['<CR>'] = cmp.mapping.confirm({ select = false }),
        ['<Tab>'] = cmp_action.luasnip_supertab(),
        ['<S-Tab>'] = cmp_action.luasnip_shift_supertab(),
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
