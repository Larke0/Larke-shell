return {
  "lervag/vimtex",
  lazy = false,
  init = function()
    vim.g.vimtex_view_method = "zathura" -- or "sioyek", "okular", etc.
    vim.g.vimtex_compiler_method = "latexmk"
  end,
}
