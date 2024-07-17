return {
  "stevearc/conform.nvim",
  event = "BufReadPre",
  config = function()
    vim.g.disable_autoformat = false
    require("conform").setup({
      formatters_by_ft = {
        css = { "prettier" },
        go = { "gofmt" },
        html = { "prettier" },
        javascript = { "prettier" },
        json = { "prettier" },
        lua = { "stylua" },
        markdown = { "prettier" },
        scss = { "prettier" },
        yaml = { "prettier" },
      },

      format_after_save = function()
        if vim.g.disable_autoformat then
          return
        else
          return { lsp_fallback = true }
        end
      end,

      formatters = {},
    })

    -- Override stylua's default indent type
    require("conform").formatters.stylua = {
      prepend_args = { "--indent-type", "Spaces" },
    }

    -- Override prettier's default indent type
    require("conform").formatters.prettier = {
      prepend_args = { "--tab-width", "2" },
    }

    -- Toggle format on save
    vim.api.nvim_create_user_command("ConformToggle", function()
      vim.g.disable_autoformat = not vim.g.disable_autoformat
      print("Conform " .. (vim.g.disable_autoformat and "disabled" or "enabled"))
    end, {
      desc = "Toggle format on save",
    })
  end,
}
