-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- フォーカス復帰時に macOS の外観を再判定し、background と
-- tokyonight の variant（day/moon）を切り替える。
vim.api.nvim_create_autocmd("FocusGained", {
  group = vim.api.nvim_create_augroup("macos_appearance_sync", { clear = true }),
  callback = function()
    if vim.fn.has("mac") == 0 then
      return
    end
    local out = vim.fn.system("defaults read -g AppleInterfaceStyle 2>/dev/null")
    local bg = out:match("Dark") and "dark" or "light"
    if vim.o.background ~= bg then
      vim.o.background = bg
      pcall(vim.cmd.colorscheme, bg == "light" and "tokyonight-day" or "tokyonight-moon")
    end
  end,
})
