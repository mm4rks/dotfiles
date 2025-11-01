local builtin = require('telescope.builtin')
local actions = require('telescope.actions')

require('telescope').setup {
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
            fuzzy = true,             -- false will only do exact matching
            override_generic_sorter = true, -- override the generic sorter
            override_file_sorter = true, -- override the file sorter
            case_mode = "smart_case", -- or "ignore_case" or "respect_case"
            -- the default case_mode is "smart_case"
        }
    }
}

-- To get fzf loaded and working with telescope, you need to call
-- load_extension, somewhere after setup function:
require('telescope').load_extension('fzf')

local function find_git_or_regular_files()
  local is_git_repo = vim.fn.system("git rev-parse --is-inside-work-tree > /dev/null 2>&1")
  if vim.v.shell_error == 0 then
    require('telescope.builtin').git_files()
  else
    require('telescope.builtin').find_files()
  end
end

vim.keymap.set('n', '<C-f>', builtin.find_files, {})
-- vim.keymap.set('n', '<C-j>', builtin.git_files, {})
vim.keymap.set('n', '<C-p>', find_git_or_regular_files, {})
vim.keymap.set('n', 'ö', find_git_or_regular_files, {})
vim.keymap.set('n', '<leader>gb', builtin.git_branches, {})
vim.keymap.set('n', '<leader>rg', function()
    builtin.live_grep({ default_text = vim.fn.expand("<cword>") })
end)
vim.keymap.set('n', '<leader>dg', builtin.diagnostics, {})
-- nnoremap <leader>rs :Telescope lsp_dynamic_workspace_symbols<CR>
