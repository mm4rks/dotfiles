local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local make_entry = require "telescope.make_entry"
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"
local conf = require("telescope.config").values

local M = {
  last_scan_file = nil
}

function M.joern_results_picker(results_file)
  local results = {}
  local file = io.open(results_file, "r")
  if not file then
    print("Error: Could not open " .. results_file)
    return
  end
  M.last_scan_file = results_file -- Store the last used file

  for line in file:lines() do
    local _, _, description, file_path, line_num = string.find(line, "Result: [%d.]+ : (.*): ([^:]+):(%d+):.*")
    if file_path and line_num then
      table.insert(results, {
        filename = file_path,
        lnum = tonumber(line_num),
        text = description,
        ordinal = description .. " @ " .. file_path .. ":" .. line_num,
        display = description .. " @ " .. file_path .. ":" .. line_num,
      })
    end
  end
  file:close()

  pickers.new({}, {
    prompt_title = "Joern Scan Results",
    finder = finders.new_table {
      results = results,
      entry_maker = function(entry)
        return {
          value = entry,
          display = entry.display,
          ordinal = entry.ordinal,
          filename = entry.filename,
          lnum = entry.lnum,
        }
      end
    },
    sorter = require("telescope.sorters").get_generic_fuzzy_sorter(),
    previewer = conf.grep_previewer({}),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if selection then
          vim.cmd("edit +" .. selection.lnum .. " " .. selection.filename)
        end
      end)
      return true
    end,
  }):find()
end

vim.api.nvim_create_user_command(
  'JoernScan',
  function(opts)
    if #opts.fargs == 0 then
      print("Usage: JoernScan <results_file>")
      return
    end
    M.joern_results_picker(opts.fargs[1])
  end,
  { nargs = 1, complete = 'file' }
)

vim.keymap.set("n", "<leader>js", function()
  vim.ui.input({ prompt = "Joern scan file: ", default = M.last_scan_file, completion = "file" }, function(input)
    if input then
      M.joern_results_picker(input)
    end
  end)
end, { noremap = true, silent = true })


return M