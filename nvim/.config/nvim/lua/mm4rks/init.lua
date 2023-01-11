require("mm4rks.packer")
require("mm4rks.remap")
require("mm4rks.set")


-- Highlight on yank
local yankGrp = vim.api.nvim_create_augroup("YankHighlight", { clear = true })
vim.api.nvim_create_autocmd("TextYankPost", {
  command = "silent! lua vim.highlight.on_yank()",
  group = yankGrp,
})

-- templates
local templateGrp = vim.api.nvim_create_augroup("TemplateGrp", { clear = true })
vim.api.nvim_create_autocmd("BufNewFile", {
    pattern = "README.md",
    command = "0r ~/.config/nvim/templates/readme.md",
    group = templateGrp,
})
vim.api.nvim_create_autocmd("BufNewFile", {
    pattern = "*.c",
    command = "0r ~/.config/nvim/templates/main.c",
    group = templateGrp,
})
vim.api.nvim_create_autocmd("BufNewFile", {
    pattern = "*.py",
    command = "0r ~/.config/nvim/templates/script.py",
    group = templateGrp,
})
vim.api.nvim_create_autocmd("BufNewFile", {
    pattern = "*.sh",
    command = "0r ~/.config/nvim/templates/script.sh",
    group = templateGrp,
})
