require("langmap")

-- Load old config
local config = vim.fn.stdpath("config")
vim.cmd("source " .. config .. "/raw.vim")
vim.cmd("source " .. config .. "/default.vim")
vim.cmd("source " .. config .. "/coc.vim")

vim.g.mapleader = "m"

-- Ranger is a default navigator
vim.api.nvim_create_user_command("R", "Ranger", {})
vim.api.nvim_create_user_command("Ex", "Ranger", {})

-- Remove trailing whitespace
vim.keymap.set('n', '<F5>', [[:%s/\s\+$//e<CR>]], {})

-- Edit a previous search in the command line, without running it.
--   m/  edit last search (forward prompt),  m?  edit last (backward)
--   2m/ 3m? ...  edit the Nth-previous search ([count] = how far back)
-- Then tweak it and <CR> to run, or <Esc> to cancel.
local function edit_prev_search(backward)
  local n = vim.v.count1 -- 1 = last search, 2 = the one before, ...
  local pat = vim.fn.histget('search', -n)
  if pat == '' then
    vim.notify('no search #' .. n .. ' in history', vim.log.levels.WARN)
    return
  end
  -- feed `/pattern` (or `?pattern`) with no <CR>: lands in the prompt, mid-edit
  vim.api.nvim_feedkeys((backward and '?' or '/') .. pat, 'n', false)
end
vim.keymap.set('n', '<leader>/', function() edit_prev_search(false) end,
  { silent = true, desc = 'Edit previous search (forward)' })
vim.keymap.set('n', '<leader>?', function() edit_prev_search(true) end,
  { silent = true, desc = 'Edit previous search (backward)' })
