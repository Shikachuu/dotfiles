return {
  "windwp/nvim-ts-autotag",
  lazy = true,
  event = "InsertEnter",
  setup = function()
    require("nvim-ts-autotag").setup({
      opts = {
        enable_close = true, -- Auto close tags
        enable_rename = true, -- Auto rename tags
      },
    })
  end,
}
