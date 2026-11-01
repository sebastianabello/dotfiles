local augroup = vim.api.nvim_create_augroup("user_config", { clear = true })

-- Resaltar texto al copiarlo
vim.api.nvim_create_autocmd("TextYankPost", {
  group = augroup,
  callback = function() vim.hl.on_yank() end,
})

-- Volver a la última posición al reabrir un archivo
vim.api.nvim_create_autocmd("BufReadPost", {
  group = augroup,
  callback = function(ev)
    local mark = vim.api.nvim_buf_get_mark(ev.buf, '"')
    if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(ev.buf) then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})
