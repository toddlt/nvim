-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = LazyVim.safe_keymap_set
-- 设置折叠代码的快捷键
map("n", "<space", "za", { desc = "", remap = false, silent = true })
-- 设置保存和退出的快捷键
map("n", "<leader>q", ":q<CR>", { desc = "", remap = false, silent = true })
map("n", "<leader>w", ":w<CR>", { desc = "", remap = false, silent = true })
map("n", "<leader>x", ":x<CR>", { desc = "", remap = false, silent = true })
