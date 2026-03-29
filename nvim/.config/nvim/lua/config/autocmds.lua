-- Highlight on yank
local yankGrp = vim.api.nvim_create_augroup("YankHighlight", { clear = true })
vim.api.nvim_create_autocmd("TextYankPost", {
    command = "silent! lua vim.hl.on_yank()",
    group = yankGrp,
})

-- Break lines in LaTeX files
vim.api.nvim_create_autocmd("FileType", {
    pattern = "tex",
    command = "setlocal wrap linebreak"
})

-- Auto open quickfix window
vim.api.nvim_create_autocmd("QuickFixCmdPost", {
  pattern = "[^`]*",
  command = "cwindow",
})

-- Delete quickfix item with dd
vim.api.nvim_create_autocmd("FileType", {
  pattern = "qf",
  callback = function()
    vim.keymap.set("n", "dd", function()
        local current_line = vim.fn.line('.')
        local qf_list = vim.fn.getqflist()

        if current_line > #qf_list then
          return
        end

        table.remove(qf_list, current_line)
        vim.fn.setqflist(qf_list, 'r')
      end,
      { noremap = true, silent = true, buffer = true, desc = "Delete qf item" }
    )
  end,
})
