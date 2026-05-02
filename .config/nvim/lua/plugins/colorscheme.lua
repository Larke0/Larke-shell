return {
  {
    "nvim-mini/mini.base16",
    version = false,
    priority = 1000,
    config = function()
      local colors = require("matugen_colors")
      require("mini.base16").setup({
        palette = colors,
        use_cterm = false,
      })
      vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
      vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
      vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" })
    end,
  },
}
