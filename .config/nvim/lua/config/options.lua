-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- macOS の Light/Dark 外観に追従して background を切り替える（wezterm と同期）
local function macos_appearance()
  if vim.fn.has("mac") == 0 then
    return "dark"
  end
  local out = vim.fn.system("defaults read -g AppleInterfaceStyle 2>/dev/null")
  return out:match("Dark") and "dark" or "light"
end

vim.opt.background = macos_appearance()
