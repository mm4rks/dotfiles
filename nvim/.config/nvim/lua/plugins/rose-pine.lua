return {
	"rose-pine/neovim",
	name = "rose-pine",
	priority = 1000, -- Ensures this plugin loads first
	config = function()
		-- Call setup with your options
		require("rose-pine").setup({
			--disable_background = true,
			disable_italics = true,
		})

		-- Set the colorscheme
		vim.cmd("colorscheme rose-pine")
	end
}
