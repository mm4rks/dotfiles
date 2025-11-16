return {
    {
        "alexghergh/nvim-tmux-navigation",
        config = function()
            local nvim_tmux_nav = require('nvim-tmux-navigation')

            nvim_tmux_nav.setup {
                disable_when_zoomed = true -- defaults to false
            }

            vim.keymap.set({'n', 't'}, "<C-h>", nvim_tmux_nav.NvimTmuxNavigateLeft)
            vim.keymap.set({'n', 't'}, "<C-j>", nvim_tmux_nav.NvimTmuxNavigateDown)
            vim.keymap.set({'n', 't'}, "<C-k>", nvim_tmux_nav.NvimTmuxNavigateUp)
            vim.keymap.set({'n', 't'}, "<C-l>", nvim_tmux_nav.NvimTmuxNavigateRight)
        end
    },
    'tpope/vim-fugitive',
    'tpope/vim-surround',
    'tpope/vim-repeat',
    'lewis6991/gitsigns.nvim',
    {
        'nvim-lualine/lualine.nvim',
        dependencies = { 'nvim-tree/nvim-web-devicons' },
        config = function()
            require('lualine').setup({
                sections = {
                    lualine_c = {
                        {
                            'filename',
                            path = 1, -- relative to current working directory
                            -- path = 4, -- relative to git root
                            -- path = 2, -- absolute path
                        }
                    }
                }
            })
        end
    },
}
