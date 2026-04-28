
local f = ("/tmp/nvim_%d_layout"):format(vim.fn.getpid())

vim.api.nvim_create_autocmd("InsertLeave", {
  callback = function()
    vim.fn.jobstart(
      string.format("niri msg -j keyboard-layouts | jq -r .current_idx > %s && niri msg action switch-layout 0", f),
      { detach = true }
    )
  end,
})

vim.api.nvim_create_autocmd("InsertEnter", {
  callback = function()
    vim.fn.jobstart(
      string.format("niri msg action switch-layout \"$(cat %s 2>/dev/null || echo 0)\"", f),
      { detach = true }
    )
  end,
})
