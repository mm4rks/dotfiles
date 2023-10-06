local nvim_tmux_nav = require('nvim-tmux-navigation')

nvim_tmux_nav.setup {
    disable_when_zoomed = true -- defaults to false
}

vim.keymap.set({'n', 't'}, "<C-h>", nvim_tmux_nav.NvimTmuxNavigateLeft)
vim.keymap.set({'n', 't'}, "<C-j>", nvim_tmux_nav.NvimTmuxNavigateDown)
vim.keymap.set({'n', 't'}, "<C-k>", nvim_tmux_nav.NvimTmuxNavigateUp)
vim.keymap.set({'n', 't'}, "<C-l>", nvim_tmux_nav.NvimTmuxNavigateRight)
-- vim.keymap.set('n', "<C-\\>", nvim_tmux_nav.NvimTmuxNavigateLastActive)
-- vim.keymap.set('n', "<C-Space>", nvim_tmux_nav.NvimTmuxNavigateNext)
