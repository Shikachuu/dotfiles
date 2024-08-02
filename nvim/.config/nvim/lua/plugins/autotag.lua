return {
  "windwp/nvim-ts-autotag",
  setup = function()
    require("nvim-ts-autotag").setup({
      opts = {
        enable_close = true, -- Auto close tags
        enable_rename = true, -- Auto rename tags
      },
    })
  end,
}
