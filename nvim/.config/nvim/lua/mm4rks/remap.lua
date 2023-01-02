vim.g.mapleader = " "
vim.keymap.set("n", "<leader>e", vim.cmd.Ex)

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

-- This is going to get me cancelled
vim.keymap.set("i", "<C-c>", "<Esc>")
vim.keymap.set("i", "jj", "<Esc>")
vim.keymap.set("i", "jk", "<Esc>")
vim.keymap.set("i", "kj", "<Esc>")

vim.keymap.set("n", "Q", "<nop>")
vim.keymap.set("n", "<leader>f", vim.lsp.buf.format)

-- pane movement
vim.keymap.set("n", "<leader>h", ":wincmd h<CR>", {noremap = true, silent = true })
vim.keymap.set("n", "<leader>j", ":wincmd j<CR>", {noremap = true, silent = true })
vim.keymap.set("n", "<leader>k", ":wincmd k<CR>", {noremap = true, silent = true })
vim.keymap.set("n", "<leader>l", ":wincmd l<CR>", {noremap = true, silent = true })

-- highlight search results toggle
vim.keymap.set("n", "<leader>#", ":set hlsearch!<CR>", {noremap = true, silent = true })

-- map :W to :w TODO autocmd
vim.cmd.command("W", "w")
vim.cmd.command("Wq", "wq")
vim.cmd.command("WQ", "wq")
vim.cmd.command("Q", "q")

-- " indent/unindent with tab/shift-tab
vim.keymap.set("i", "<S-Tab>", "<Esc><<i")
vim.keymap.set("n", "<Tab>", ">>")
vim.keymap.set("n", "<S-Tab>", "<<")
vim.keymap.set("v", "<Tab>", ">", {noremap = true })
vim.keymap.set("v", "<S-Tab>", "<")

-- vim.keymap.set("n", "<C-k>", "<cmd>cnext<CR>zz")
-- vim.keymap.set("n", "<C-j>", "<cmd>cprev<CR>zz")
-- vim.keymap.set("n", "<leader>k", "<cmd>lnext<CR>zz")
-- vim.keymap.set("n", "<leader>j", "<cmd>lprev<CR>zz")
