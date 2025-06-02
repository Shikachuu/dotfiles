return {
  "echasnovski/mini.surround",
  version = "*",
  config = function()
    require("mini.surround").setup({
      mappings = {
        add = "sa",
        delete = "sd",
        replace = "sr",
        find = "",
        update_n_lines = "",
        suffix_last = "",
        suffix_next = "",
        find_left = "",
      },
    })
  end,
}
