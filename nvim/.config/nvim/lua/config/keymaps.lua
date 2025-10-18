-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- move selected lines
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

vim.keymap.set("n", "J", "mzJ`z")
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")


-- greatest remap ever
vim.keymap.set("x", "<leader>p", [["_dP]])

-- yank to clipboard
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]])
vim.keymap.set("n", "<leader>Y", [["+Y]])

-- yank rest of line
vim.keymap.set("n", "Y", "y$")

-- paste from clipboard
vim.keymap.set({ "n", "v" }, "<leader>p", [["+p]])
vim.keymap.set({ "n", "v" }, "<leader>P", [["+P]])
vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]])
-- command mode remaps
vim.keymap.set("c", "<C-a>", "<Home>", { noremap = true })
vim.keymap.set("c", "<C-e>", "<End>", { noremap = true })
vim.keymap.set("c", "<C-k>", "<Up>", { noremap = true })
vim.keymap.set("c", "<C-j>", "<Down>", { noremap = true })

-- Exit to normal mode
vim.keymap.set("i", "<C-c>", "<Esc>")
vim.keymap.set("i", "jj", "<Esc>")
vim.keymap.set("i", "jk", "<Esc>")
vim.keymap.set("i", "kj", "<Esc>")

-- normal mode remaps
vim.keymap.set("n", "Q", "<nop>")
vim.keymap.set("n", "<BS>", "ciw")
vim.keymap.set("n", "<leader>f", vim.lsp.buf.format)

-- visual mode remaps
vim.keymap.set("v", "<BS>", "c")

-- C-d, C-u -> }, { move blocks
vim.keymap.set({ "n", "x" }, "<C-d>", "}")
vim.keymap.set({ "n", "x" }, "<C-u>", "{")

-- H to move to the first character in a line
vim.keymap.set("n", "H", "^")

-- L to move to the last character in a line
vim.keymap.set("n", "L", "g_")

-- map :W to :w
vim.cmd.command("W", "w")
vim.cmd.command("Wq", "wq")
vim.cmd.command("WQ", "wq")
vim.cmd.command("Q", "q")

-- " indent/unindent with tab/shift-tab
vim.keymap.set("i", "<S-Tab>", "<Esc><<i")
vim.keymap.set("n", "<Tab>", ">>")
vim.keymap.set("n", "<S-Tab>", "<<")
vim.keymap.set("v", "<Tab>", ">", { noremap = true })
vim.keymap.set("v", "<S-Tab>", "<")

-- highlight search results toggle
vim.keymap.set("n", "<leader>#", ":set hlsearch!<CR>", { noremap = true, silent = true })
