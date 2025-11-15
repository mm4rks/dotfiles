return {
    {
        'nvim-telescope/telescope.nvim',
        version = 'v0.1.9',
        dependencies = { 'nvim-lua/plenary.nvim' }
    },
    { 'nvim-telescope/telescope-fzf-native.nvim', build = 'cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release --target install' },
    { "alexghergh/nvim-tmux-navigation" },
    { "nvim-treesitter/nvim-treesitter",          branch = 'master',                                                                                              lazy = false, build = ":TSUpdate" },
    'windwp/nvim-autopairs',
    'tpope/vim-fugitive',
    'tpope/vim-surround',
    'tpope/vim-repeat',
    'lewis6991/gitsigns.nvim',
    {
        'nvim-lualine/lualine.nvim',
        dependencies = { 'nvim-tree/nvim-web-devicons' }
    },
}
