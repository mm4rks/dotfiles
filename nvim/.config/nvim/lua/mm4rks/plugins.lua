-- nvim-treesitter configuration
require'nvim-treesitter.configs'.setup {
  -- A list of parser names, or "all".
  -- To add more parsers, add them to this list and run `:TSUpdate`
  ensure_installed = { "c", "python" },

  -- Install parsers synchronously (only applied to `ensure_installed`)
  sync_install = false,

  -- Automatically install missing parsers when entering buffer is disabled.
  -- Run :TSInstall <language> to install a new parser.
  auto_install = false,

  highlight = {
    enable = true,
    -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
    -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
    -- Using this option may slow down your editor, and you may see some duplicate highlights.
    -- Instead of true it can also be a list of languages
    additional_vim_regex_highlighting = false,
  },
  indent = {
    enable = true
  },
}

-- nvim-autopairs configuration
require('nvim-autopairs').setup{}
