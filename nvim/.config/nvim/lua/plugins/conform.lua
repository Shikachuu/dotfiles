return {
  "stevearc/conform.nvim",
  event = "BufReadPre",
  config = function()
    vim.g.disable_autoformat = false

    local function use_web_formatter()
      local biome_config_pattern = require("lspconfig.util").root_pattern("biome.json", "biome.jsonc")
      local has_biome_file = biome_config_pattern(vim.fn.getcwd()) ~= nil
      if require("conform").get_formatter_info("biome") and has_biome_file then
        return { "biome" }
      else
        return { "prettier" }
      end
    end

    require("conform").setup({
      formatters_by_ft = {
        css = use_web_formatter,
        go = { "gofmt" },
        html = use_web_formatter,
        javascript = use_web_formatter,
        typescript = use_web_formatter,
        typescriptreact = use_web_formatter,
        javascriptreact = use_web_formatter,
        json = use_web_formatter,
        lua = { "stylua" },
        markdown = { "prettier" },
        scss = use_web_formatter,
        yaml = use_web_formatter,
        terraform = { "tfmt" },
        hcl = { "tfmt" },
        tf = { "tfmt" },
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

    require("conform").formatters.tfmt = {
      command = "terraform",
      args = { "fmt", "-" },
      stdin = true,
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
