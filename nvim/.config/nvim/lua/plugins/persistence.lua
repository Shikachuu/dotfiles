return {
  "folke/persistence.nvim",
  event = "BufReadPre",
  opts = {},
  keys = {
    {
      "<leader>qs",
      function()
        require("persistence").load()
      end,
      desc = "Restore Session",
    },
    {
      "<leader>qS",
      function()
        require("persistence").select()
      end,
      desc = "Select Session",
    },
    {
      "<leader>ql",
      function()
        require("persistence").load({ last = true })
      end,
      desc = "Restore Last Session",
    },
    {
      "<leader>qd",
      function()
        require("persistence").stop()
      end,
      desc = "Don't Save Current Session",
    },
  },
  config = function(_, opts)
    require("persistence").setup(opts)

    -- Auto-restore session on startup
    vim.api.nvim_create_autocmd("VimEnter", {
      group = vim.api.nvim_create_augroup("persistence_auto_restore", { clear = true }),
      callback = function()
        -- Only restore if nvim was started without arguments
        if vim.fn.argc() == 0 then
          require("persistence").load()
        end
      end,
      nested = true,
    })
  end,
}
