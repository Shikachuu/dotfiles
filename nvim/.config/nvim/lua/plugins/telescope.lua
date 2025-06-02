return {
  {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.8",
    config = function()
      local telescope_config = require("telescope.config")
      local vimgrep_arguments = { unpack(telescope_config.values.vimgrep_arguments) }
      -- Add search option for hidden files except .git
      table.insert(vimgrep_arguments, "--hidden")
      table.insert(vimgrep_arguments, "--glob")
      table.insert(vimgrep_arguments, "!**/.git/**")
      table.insert(vimgrep_arguments, "--glob")
      table.insert(vimgrep_arguments, "!**/node_modules/**")
      require("telescope").setup({
        extensions = {
          file_browser = {
            follow_symlinks = true,
            hidden = true,
          },
        },
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
