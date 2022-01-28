require'nvim-treesitter.configs'.setup {
  highlight = {
    enable = true,
    additional_vim_regex_highlighting = false,
  },
  incremental_selection = {
    enable = true,
  },
}

require('spellsitter').setup {
  hl = 'SpellBad',
  captures = {'comment'},  -- set to {} to spellcheck everything
}

-- require'nvim-treesitter.configs'.setup {
--   rainbow = {
--     enable = true,
--     extended_mode = false, -- Also highlight non-bracket delimiters like html tags, boolean or table: lang -> boolean
--   }
-- }
