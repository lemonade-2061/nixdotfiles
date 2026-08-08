-- tokyonight を背景透過で使う
-- 背景はターミナル (kitty) 側の色・透過がそのまま見える
return {
  {
    "folke/tokyonight.nvim",
    opts = {
      style = "storm", -- グレー寄りの青トーン
      transparent = true,
      styles = {
        sidebars = "transparent",
        floats = "transparent",
      },
    },
  },
}
