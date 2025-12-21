return {

  --
  -- The Alpha dashboard
  --
  {
    "goolord/alpha-nvim",
    event = "VimEnter",
    opts = function()
      local dashboard = require("alpha.themes.dashboard")
      local logo = [[
                        .     *   .          +                  ..             .             *
             + '                                         .           *  '       .    o  
                        +      '      .    .             +  |     +                   ' 
               o'          o  +  |                         -o-         .   '            
                               o-+-       ' '   .       ' * |                . '        
        *            *           |        .          +  .' *       o    .              o
        '             +        o+      +    |  .                     '                  
            * '.               .          --o-- +   .                     o  +          
             .  . +               .  +      |                 '          *  o   +       
             '        '*         *.    '            '     '   +                       .
      ]]

      dashboard.section.header.val = vim.split(logo, "\n")
      dashboard.section.buttons.val = {
        dashboard.button("f", " " .. " Find file",       "<cmd> Telescope find_files <cr>"),
        dashboard.button("n", " " .. " New file",        "<cmd> ene <BAR> startinsert <cr>"),
        dashboard.button("r", " " .. " Recent files",    "<cmd> Telescope oldfiles <cr>"),
        dashboard.button("g", " " .. " Find text",       "<cmd> Telescope live_grep <cr>"),
        dashboard.button("c", " " .. " Config",          "<cmd> Telescope find_files cwd=~/.config/nvim <cr>"), 
        dashboard.button("s", " " .. " Restore Session", "<cmd> lua require('persistence').load() <cr>"),
        dashboard.button("l", "󰒲 " .. " Lazy",            "<cmd> Lazy <cr>"),
        dashboard.button("q", " " .. " Quit",            "<cmd> qa <cr>"),
      }

      -- Set highlights
      for _, button in ipairs(dashboard.section.buttons.val) do
        button.opts.hl = "AlphaButtons"
        button.opts.hl_shortcut = "AlphaShortcut"
      end
      dashboard.section.header.opts.hl = "AlphaHeader"
      dashboard.section.buttons.opts.hl = "AlphaButtons"
      dashboard.section.footer.opts.hl = "AlphaFooter"
      dashboard.opts.layout[1].val = 1
      return dashboard
    end,
    config = function(_, dashboard)
      -- Setup alpha
      require("alpha").setup(dashboard.opts)

      -- Add lazy.nvim stats to the footer
      vim.api.nvim_create_autocmd("User", {
        once = true,
        pattern = "LazyDone", -- Use 'LazyDone' from lazy.nvim manager
        callback = function()
          local stats = require("lazy").stats()
          local ms = (math.floor(stats.startuptime * 100 + 0.5) / 100)
          dashboard.section.footer.val = "⚡ Neovim loaded "
            .. stats.loaded
            .. "/"
            .. stats.count
            .. " plugins in "
            .. ms
            .. "ms"
          pcall(vim.cmd.AlphaRedraw) -- Redraw to show the updated footer
        end,
      })
    end,
  }, -- Note the comma separating the two plugins

  --
  -- Session management
  --
  {
    "folke/persistence.nvim",
    event = "BufReadPre", -- this will only start session saving when an actual file was opened
    opts = {
      -- add any custom options here
    },
  },

}
