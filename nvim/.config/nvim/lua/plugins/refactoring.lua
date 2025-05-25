return {
  "ThePrimeagen/refactoring.nvim",
  lazy = true,
  keys = {
    { "<leader>es", "<cmd>Refactor extract<CR>", desc = "[e]xtract [s]cope", mode = "x" },
    { "<leader>ev", "<cmd>Refactor extract_var<CR>", desc = "[e]xtract [v]ariable", mode = "x" },
    { "<leader>iv", "<cmd>Refactor inline_var<CR>", desc = "[i]line [v]ariable", mode = { "n", "x" } },
  },
  dependencies = {
    { "nvim-lua/plenary.nvim" },
    { "nvim-treesitter/nvim-treesitter" },
  },
  config = function()
    require("refactoring").setup({
      show_success_message = false,
      keymaps = {
        noremap = true,
        silent = true,
      },
    })
  end,
}
-- vim: ts=2 sts=2 sw=2 et
