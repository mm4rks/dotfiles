-- Highlight on yank
local yankGrp = vim.api.nvim_create_augroup("YankHighlight", { clear = true })
vim.api.nvim_create_autocmd("TextYankPost", {
    command = "silent! lua vim.highlight.on_yank()",
    group = yankGrp,
})

-- Break lines in LaTeX files
vim.api.nvim_create_autocmd("FileType", {
    pattern = "tex",
    command = "setlocal wrap linebreak"
})

