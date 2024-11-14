return {
  "ThePrimeagen/harpoon",
  branch = "harpoon2",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    local harpoon = require("harpoon")

    harpoon:setup()
    vim.keymap.set("n", "<leader>a", function()
      harpoon:list():add()
    end)
    vim.keymap.set("n", "<C-e>", function()
      harpoon.ui:toggle_quick_menu(harpoon:list())
    end, { desc = "opens the harpoon list" })
    vim.keymap.set("n", "<leader><Left>", function()
      harpoon:list():prev({ ui_nav_wrap = true })
    end, { desc = "go [L]eft on the harpoon list" })
    vim.keymap.set("n", "<leader><Right>", function()
      harpoon:list():next({ ui_nav_wrap = true })
    end, { desc = "go [R]ight on the harpoon list" })
    vim.keymap.set("n", "<leader>hfc", function()
      harpoon:list():clear()
    end, { desc = "clear the harpoon list" })
  end,
}
