-- Set charsets
vim.opt.encoding = "utf-8"
vim.opt.fileencoding = "utf-8"

-- Set the window properties like row nums and title bar
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.showmode = false
vim.opt.showcmd = true
vim.opt.termguicolors = true
vim.opt.pumblend = 0

-- Use global clipboard shared with X or Wayland
vim.opt.clipboard = "unnamedplus"
vim.opt.undofile = true
vim.opt.breakindent = true
vim.opt.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- Serach config
vim.opt.hlsearch = true
vim.opt.ignorecase = true

-- Configure indent
vim.opt.autoindent = true
vim.opt.smartindent = true

-- Tab and backspace
vim.opt.ts = 4
vim.opt.sw = 4
vim.opt.softtabstop = 2
vim.opt.expandtab = true
vim.opt.wrap = false
vim.opt.scrolloff = 5
vim.opt.backspace = { "indent", "eol", "start" }

vim.opt.foldlevelstart = 99

vim.opt.title = true

vim.diagnostic.config({
  float = { border = "rounded" },
  --virtual_text = true,
  virtual_lines = true,
})
