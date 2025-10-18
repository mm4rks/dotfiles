return {
  "nvim-treesitter/nvim-treesitter",
  opts = {
    incremental_selection = {
      enable = true,
      keymaps = {
        init_selection = 'v',
        scope_incremental = '<M-v>',
        node_incremental = 'v',
        node_decremental = 'V',
      },
    },
  },
}
