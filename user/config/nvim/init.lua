
vim.cmd("source ~/.config/nvim/init.vim")

vim.api.nvim_create_user_command("R", "Ranger", {})
vim.api.nvim_create_user_command("Ex", "Ranger", {})
