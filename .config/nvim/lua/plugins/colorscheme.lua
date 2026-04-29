-- LazyVim のデフォルト colorscheme を上書きし、background に応じて
-- tokyonight-day / tokyonight-moon を明示的に選択する。
-- （`require("tokyonight").load()` 経由だと style と bg が不整合のとき bg を
--  強制上書きされるため、variant を直接指定する）
return {
  {
    "folke/tokyonight.nvim",
    opts = {
      -- 検索 / Visual 選択ハイライトの bg は既定のまま、
      -- 文字色を高コントラスト（Light=黒 / Dark=白）+ bold にして可読性を上げる
      on_highlights = function(hl, _c)
        local strong_fg = vim.o.background == "light" and "#000000" or "#ffffff"
        for _, name in ipairs({ "Search", "IncSearch", "CurSearch", "Visual", "VisualNOS" }) do
          local cur = hl[name]
          if type(cur) == "table" then
            cur.fg = strong_fg
            if name ~= "Visual" and name ~= "VisualNOS" then
              cur.bold = true
            end
          end
        end
      end,
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = function()
        vim.cmd.colorscheme(vim.o.background == "light" and "tokyonight-day" or "tokyonight-moon")
      end,
    },
  },
}
