return {
    {
        'nvim-telescope/telescope.nvim',
        version = '0.1.9',
        dependencies = { 'nvim-lua/plenary.nvim',
            { 'nvim-telescope/telescope-fzf-native.nvim', build = 'cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release --target install' },
        },
        config = function()
            local telescope = require('telescope')
            local builtin = require('telescope.builtin')
            local actions = require('telescope.actions')
            local joern = require('config.joern')

            telescope.setup {
                defaults = {
                    mappings = {
                        i = {
                            ["<C-j>"] = actions.move_selection_next,
                            ["<C-k>"] = actions.move_selection_previous,
                        }
                    }
                },
                extensions = {
                    fzf = {
                        fuzzy = true,
                        override_generic_sorter = true,
                        override_file_sorter = true,
                        case_mode = "smart_case",
                    }
                }
            }
            require('telescope').load_extension('fzf')

            local function find_git_or_regular_files()
                local is_git_repo = vim.fn.system("git rev-parse --is-inside-work-tree > /dev/null 2>&1")
                if vim.v.shell_error == 0 then
                    require('telescope.builtin').git_files()
                else
                    require('telescope.builtin').find_files()
                end
            end

            local function get_visual_selection()
                vim.cmd('noau normal! "vy"')
                local text = vim.fn.getreg('v')
                vim.fn.setreg('v', {})
                text = text:gsub('\n', '')
                return text
            end

            local pickers = require "telescope.pickers"
            local finders = require "telescope.finders"
            local make_entry = require "telescope.make_entry"
            local conf = require "telescope.config".values

            local live_multigrep = function(opts)
                opts = opts or {}
                opts.cwd = opts.cwd or vim.uv.cwd()

                local finder = finders.new_async_job {
                    command_generator = function(prompt)
                        if not prompt or prompt == "" then
                            return nil
                        end
                        local pieces = vim.split(prompt, "  ")
                        local args = { "rg" }
                        if pieces[1] and pieces[1] ~= "" then
                            table.insert(args, "-e")
                            table.insert(args, pieces[1])
                        end
                        if pieces[2] and pieces[2] ~= "" then
                            table.insert(args, "-g")
                            table.insert(args, pieces[2])
                        end
                        ---@diagnostic disable-next-line: deprecated
                        return vim.tbl_flatten {
                            args,
                            { "--color=never", "--no-heading", "--with-filename", "--line-number", "--column", "--smart-case", "--hidden" },
                        }
                    end,
                    entry_maker = make_entry.gen_from_vimgrep(opts),
                    cwd = opts.cwd,
                }

                pickers.new(opts, {
                    debounce = 100,
                    prompt_title = "Multi Grep",
                    finder = finder,
                    previewer = conf.grep_previewer(opts),
                    sorter = require("telescope.sorters").empty(),
                    default_text = opts.default_text or "", -- Pass default_text here
                }):find()
            end

            vim.keymap.set('n', '<C-f>', builtin.find_files, {})
            vim.keymap.set('n', '<C-p>', find_git_or_regular_files, {})
            vim.keymap.set('n', 'ö', find_git_or_regular_files, {})
            vim.keymap.set('n', '<leader>gb', builtin.git_branches, {})
            vim.keymap.set('n', '<leader>dg', builtin.diagnostics, {})

            local rg_base = { "--color=never", "--no-heading", "--with-filename", "--line-number", "--column", "--smart-case", "--hidden" }

            local live_cascadegrep = function(opts)
                opts = opts or {}
                opts.cwd = opts.cwd or vim.uv.cwd()

                local finder = finders.new_async_job {
                    command_generator = function(prompt)
                        if not prompt or prompt == "" then return nil end
                        local pieces = vim.split(prompt, "  ")
                        local p1 = pieces[1] ~= "" and pieces[1] or nil
                        local p2 = pieces[2] and pieces[2] ~= "" and pieces[2] or nil

                        if p1 and p2 then
                            -- synchronously get files containing p1, then search those for p2
                            local files = vim.fn.systemlist(
                                "rg -l --smart-case --hidden -e " .. vim.fn.shellescape(p1)
                            )
                            if not files or #files == 0 then return nil end
                            local cmd = { "rg", "-e", p2 }
                            for _, v in ipairs(rg_base) do table.insert(cmd, v) end
                            for _, f in ipairs(files) do table.insert(cmd, f) end
                            return cmd
                        elseif p1 then
                            local cmd = { "rg", "-e", p1 }
                            for _, v in ipairs(rg_base) do table.insert(cmd, v) end
                            return cmd
                        end
                        return nil
                    end,
                    entry_maker = make_entry.gen_from_vimgrep(opts),
                    cwd = opts.cwd,
                }

                pickers.new(opts, {
                    debounce = 100,
                    prompt_title = "Cascade Grep",
                    finder = finder,
                    previewer = conf.grep_previewer(opts),
                    sorter = require("telescope.sorters").empty(),
                    default_text = opts.default_text or "",
                }):find()
            end

            vim.keymap.set('n', '<leader>rg', function()
                live_multigrep({})
            end)
            vim.keymap.set('v', '<leader>rg', function()
                local text = get_visual_selection()
                live_multigrep({ default_text = text })
            end)

            vim.keymap.set('n', '<leader>RG', function()
                live_cascadegrep({})
            end)
            vim.keymap.set('v', '<leader>RG', function()
                local text = get_visual_selection()
                live_cascadegrep({ default_text = text })
            end)
        end,
    }
}
