return {
  {
    "scottmckendry/cyberdream.nvim",
    lazy = false,
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
        extensions = {
          mini = true
        }
      })

      vim.cmd("colorscheme cyberdream")
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
