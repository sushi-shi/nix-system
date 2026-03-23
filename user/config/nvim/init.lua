local config = vim.fn.stdpath("config")

vim.cmd("source " .. config .. "/raw.vim")
vim.cmd("source " .. config .. "/default.vim")
vim.cmd("source " .. config .. "/coc.vim")


vim.api.nvim_create_user_command("R", "Ranger", {})
vim.api.nvim_create_user_command("Ex", "Ranger", {})

vim.keymap.set('n', '<F5>', [[:%s/\s\+$//e<CR>]], {})
