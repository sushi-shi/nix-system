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
