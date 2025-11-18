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
                        if pieces[1] then
                            table.insert(args, "-e")
                            table.insert(args, pieces[1])
                        end
                        if pieces[2] then
                            table.insert(args, "-g")
                            table.insert(args, pieces[2])
                        end
                        ---@diagnostic disable-next-line: deprecated
                        return vim.tbl_flatten {
                            args,
                            { "--color=never", "--no-heading", "--with-filename", "--line-number", "--column", "--smart-case" },
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

            vim.keymap.set('n', '<leader>rg', function()
                live_multigrep({ default_text = vim.fn.expand("<cword>") })
            end)
            vim.keymap.set('v', '<leader>rg', function()
                local text = get_visual_selection()
                live_multigrep({ default_text = text })
            end)
        end,
    }
}
