return {
  "jellydn/hurl.nvim",
  dependencies = {
    "MunifTanjim/nui.nvim",
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
  ft = "hurl",
  opts = {
    -- Show debugging info
    debug = false,
    mode = "split",
    -- Default formatter
    formatters = {
      json = { "jq" },
    },
  },
  keys = {
    -- Run API request
    { "<leader>hra", "<cmd>HurlRunner<CR>", desc = "[h]url [r]un [a]ll requests" },
    { "<leader>htm", "<cmd>HurlToggleMode<CR>", desc = "[h]url [t]oggle [m]ode" },
    { "<leader>hv", "<cmd>HurlVerbose<CR>", desc = "[h]url [v]erbose mode" },
  },
}

-- vim: ts=2 sts=2 sw=2 et
