return {
    {
        "nvim-treesitter/nvim-treesitter",
        branch = "main",
        lazy = false,
        build = ":TSUpdate",
        config = function()
            local ts = require("nvim-treesitter")
            local ensure_installed = {
                "vimdoc",
                "c",
                "lua",
                "python",
                "bash",
                "javascript",
                "typescript",
                "tsx",
                "markdown",
                "markdown_inline",
                "query",
                "vim",
            }

            if ts.setup then
                ts.setup({})
            end
            if ts.install and ts.get_installed then
                local installed = {}
                for _, lang in ipairs(ts.get_installed()) do
                    installed[lang] = true
                end
                local missing = vim.tbl_filter(function(lang)
                    return not installed[lang]
                end, ensure_installed)
                if #missing > 0 then
                    ts.install(missing)
                end
            end

            -- Enable native Neovim treesitter highlighting automatically when a parser exists
            vim.api.nvim_create_autocmd("FileType", {
                group = vim.api.nvim_create_augroup("DotfilesTreesitter", { clear = true }),
                callback = function(args)
                    pcall(vim.treesitter.start, args.buf)
                end,
            })

            -- Native vim.treesitter incremental selection (replaces legacy master module)
            local selections = {}

            local function select_node(buf, node)
                if not node then
                    return
                end
                local srow, scol, erow, ecol = node:range()
                local end_row = erow + 1
                local end_col = ecol
                if ecol == 0 and erow > srow then
                    end_row = erow
                    local line = vim.api.nvim_buf_get_lines(buf, erow - 1, erow, false)[1] or ""
                    end_col = math.max(#line, 1)
                else
                    end_col = math.max(ecol, 1)
                end

                local mode = vim.api.nvim_get_mode().mode
                if mode ~= "v" and mode ~= "V" and mode ~= "\22" then
                    vim.cmd("normal! v")
                elseif mode ~= "v" then
                    vim.cmd("normal! v")
                end

                vim.api.nvim_win_set_cursor(0, { srow + 1, scol })
                vim.cmd("normal! o")
                vim.api.nvim_win_set_cursor(0, { end_row, end_col - 1 })
            end

            local function same_range(a, b)
                if not a or not b then
                    return false
                end
                local asr, asc, aer, aec = a:range()
                local bsr, bsc, ber, bec = b:range()
                return asr == bsr and asc == bsc and aer == ber and aec == bec
            end

            local function init_selection()
                local buf = vim.api.nvim_get_current_buf()
                local ok, node = pcall(vim.treesitter.get_node, { bufnr = buf })
                if not ok or not node then
                    return
                end
                selections[buf] = { node }
                select_node(buf, node)
            end

            local function node_incremental()
                local buf = vim.api.nvim_get_current_buf()
                local stack = selections[buf]
                if not stack or #stack == 0 then
                    init_selection()
                    return
                end
                local current = stack[#stack]
                local parent = current:parent()
                while parent and same_range(parent, current) do
                    parent = parent:parent()
                end
                if parent then
                    table.insert(stack, parent)
                    select_node(buf, parent)
                end
            end

            local function scope_incremental()
                local buf = vim.api.nvim_get_current_buf()
                local stack = selections[buf]
                if not stack or #stack == 0 then
                    init_selection()
                    return
                end
                local current = stack[#stack]
                local parent = current:parent()
                while parent do
                    local ptype = parent:type()
                    if not same_range(parent, current) and (
                        ptype:find("block")
                        or ptype:find("function")
                        or ptype:find("method")
                        or ptype:find("class")
                        or ptype:find("statement")
                        or ptype:find("table")
                        or not parent:parent()
                    ) then
                        table.insert(stack, parent)
                        select_node(buf, parent)
                        return
                    end
                    parent = parent:parent()
                end
            end

            local function node_decremental()
                local buf = vim.api.nvim_get_current_buf()
                local stack = selections[buf]
                if not stack or #stack <= 1 then
                    return
                end
                table.remove(stack)
                select_node(buf, stack[#stack])
            end

            vim.keymap.set("n", "vv", init_selection, { silent = true, desc = "Start treesitter selection" })
            vim.keymap.set("x", "v", node_incremental, { silent = true, desc = "Increment treesitter node selection" })
            vim.keymap.set("x", "V", node_decremental, { silent = true, desc = "Decrement treesitter node selection" })
            vim.keymap.set("x", "<M-v>", scope_incremental, { silent = true, desc = "Increment treesitter scope selection" })
        end,
    },
    {
        "windwp/nvim-autopairs",
        config = function()
            require("nvim-autopairs").setup({
                disable_filetype = { "TelescopePrompt", "vim" },
            })
        end,
    },
}

