-- ~/.config/nvim/lua/plugins/gemini-code.lua
return {
  "beloin/gemini-code.nvim",
  event = "VeryLazy",
  opts = {
    auto_start = true, -- Fires up the companion daemon using your native gemini-cli
  },
  keys = {
    { "<leader>gg", "<cmd>GeminiCode<cr>",           desc = "Toggle Gemini CLI" },
    { "<leader>ga", "<cmd>GeminiCodeAutoEdit<cr>",   desc = "Toggle Gemini CLI (auto-edit)" },
    { "<leader>da", "<cmd>GeminiCodeDiffAccept<cr>", desc = "Accept Gemini diff" },
    { "<leader>dr", "<cmd>GeminiCodeDiffDeny<cr>",   desc = "Reject Gemini diff" },
  },
}
