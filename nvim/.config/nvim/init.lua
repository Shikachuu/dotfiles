-- Install lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Set leader and localleader
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Add vim-opts
require('opts')

-- Add dependencies
require('lazy').setup('plugins')

-- Add keybinds
require('keybinds')

-- Add autocommands
require('autocommands')

if vim.loop.os_uname().sysname == "Darwin" then
  vim.cmd([[set rtp+=$HOMEBREW_PREFIX/opt/fzf]])
end

-- vim: ts=2 sts=2 sw=2 et
