return {
  "hrsh7th/nvim-cmp",
  ---@param opts cmp.ConfigSchema
  opts = function(_, opts)
    local cmp = require("cmp")

    -- Add your new mappings
    opts.mapping["<C-j>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert })
    opts.mapping["<C-k>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert })

    -- You can also unmap the default C-n and C-p if you want
    -- opts.mapping["<C-n>"] = nil
    -- opts.mapping["<C-p>"] = nil

    return opts
  end,
}
