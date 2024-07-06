return {
  "ThePrimeagen/refactoring.nvim",
  dependencies = {
    { "nvim-lua/plenary.nvim" },
    { "nvim-treesitter/nvim-treesitter" }
  },
  config = function()
    require('refactoring').setup({
      show_success_message = false,
      keymaps = {
        noremap = true,
        silent = true,
      },
    })
  end,
}
-- vim: ts=2 sts=2 sw=2 et
