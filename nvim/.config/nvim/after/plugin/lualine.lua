require('lualine').setup({
  sections = {
    lualine_c = {
      {
        'filename',
        path = 1, -- relative to current working directory
        -- path = 4, -- relative to git root
        -- path = 2, -- absolute path
      }
    }
  }
})
