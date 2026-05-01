return {
  {
    "benlubas/molten-nvim",
    version = "^1.0.0", -- recommended to avoid breaking changes
    build = ":UpdateRemotePlugins", -- essential for remote plugins to work
    init = function()
      -- Example configuration: set max height for output windows
      vim.g.molten_output_win_max_height = 12
    end,
  },
}
