local yamlls_crd = require("functions.yamlls_crd")

vim.api.nvim_set_keymap(
  "n",
  "<leader>fs",
  ":Telescope grep_string<CR>",
  { noremap = true, silent = true, desc = "[f]ind [s]tring" }
)
vim.api.nvim_set_keymap(
  "n",
  "<leader>fa",
  ":Telescope live_grep<CR>",
  { noremap = true, silent = true, desc = "[f]ind [s]tring" }
)
vim.api.nvim_set_keymap(
  "n",
  "<leader>ff",
  ":Telescope find_files<CR>",
  { noremap = true, silent = true, desc = "[f]ind [f]iles" }
)
vim.api.nvim_set_keymap(
  "n",
  "<leader>fb",
  ":Telescope file_browser<CR>",
  { noremap = true, silent = true, desc = "[f]ind [b]rowser" }
)

vim.api.nvim_set_keymap(
  "n",
  "<leader>Gb",
  ":Gitsigns toggle_current_line_blame<CR>",
  { noremap = true, silent = true, desc = "[G]it [h]istory" }
)

vim.api.nvim_set_keymap(
  "n",
  "<C-f>",
  ":Telescope current_buffer_fuzzy_find<CR>",
  { noremap = true, silent = true, desc = "[F]ind" }
)

vim.api.nvim_set_keymap(
  "n",
  "<leader>sk",
  ":Telescope keymaps<CR>",
  { noremap = true, silent = true, desc = "[s]earch [k]eymaps" }
)

vim.api.nvim_set_keymap(
  "n",
  "<leader><TAB>",
  ":Telescope buffers<CR>",
  { noremap = true, silent = true, desc = "show open buffers" }
)

vim.keymap.set("n", "<C-S-Up>", ":m -2<CR>", { noremap = true, desc = "move line up", silent = true })
vim.keymap.set("n", "<C-S-Down>", ":m +1<CR>", { noremap = true, desc = "move line down", silent = true })

vim.keymap.set("n", "<leader>spv", ":vsplit<CR>", { noremap = true, desc = "[s][p]lit [v]ertical", silent = true })
vim.keymap.set("n", "<leader>sph", ":split<CR>", { noremap = true, desc = "[s][p]lit [h]orizontal", silent = true })

vim.keymap.set("n", "<C-Q>", ":bd<CR>", { noremap = true, desc = "[q]uit current tab", silent = true })

local ts_select = require("functions.treesitter")
vim.keymap.set("n", "<CR>", ts_select.init_selection, { desc = "Init treesitter selection" })
vim.keymap.set("x", "<CR>", ts_select.node_incremental, { desc = "Expand treesitter selection" })
vim.keymap.set("x", "<TAB>", ts_select.scope_incremental, { desc = "Expand treesitter selection to scope" })
vim.keymap.set("x", "<S-TAB>", ts_select.node_decremental, { desc = "Shrink treesitter selection" })

vim.keymap.set("n", "<leader>!", "za", { noremap = true, desc = "toggle fold under cursor", silent = true })
vim.keymap.set("n", "<leader>.", "zA", { noremap = true, desc = "toggle all fold in file", silent = true })

vim.keymap.set(
  "n",
  "<leader>pcrd",
  yamlls_crd.open_picker,
  { noremap = true, desc = "[p]ick yaml [crd]", silent = true }
)
