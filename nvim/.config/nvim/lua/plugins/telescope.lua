return {
  {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.6",
    config = function()
      local telescopeConfig = require("telescope.config")
      local vimgrep_arguments = { unpack(telescopeConfig.values.vimgrep_arguments) }
      -- Add search option for hidden files except .git
      table.insert(vimgrep_arguments, "--hidden")
      table.insert(vimgrep_arguments, "--glob")
      table.insert(vimgrep_arguments, "!**/.git/**")
      table.insert(vimgrep_arguments, "--glob")
      table.insert(vimgrep_arguments, "!**/node_modules/**")
      require("telescope").setup({
        defaults = {
          vimgrep_arguments = vimgrep_arguments,
        },
        pickers = {
          find_files = {
            find_command = {
              "rg",
              "--files",
              "--hidden",
              "--glob",
              "!**/.git/**",
              "--glob",
              "!**/node_modules/**",
            },
          },
        },
      })
    end,
    dependencies = { { "nvim-lua/plenary.nvim" } },
  },
  {
    "nvim-telescope/telescope-file-browser.nvim",
    dependencies = { "nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim" },
  },
}
-- vim: ts=2 sts=2 sw=2 et
