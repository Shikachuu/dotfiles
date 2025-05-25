return {
  {
    "scottmckendry/cyberdream.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("cyberdream").setup({
        transparent = true,
        italic_comments = true,
        hide_fillchars = true,
        terminal_colors = false,
        borderless_telescope = { border = true, style = "flat" },
        theme = {
          variant = "auto",
        },
        options = {
          theme = "auto",
        },
        extensions = {
          mini = true,
          gitsigns = true,
          lazy = true,
          treesitter = true,
        },
      })

      vim.cmd("colorscheme cyberdream")
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
