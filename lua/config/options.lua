-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- 设置 leader key
vim.g.mapleader = ";"
vim.g.autoformat = false
vim.g.snacks_animate = false

vim.g.interestingWordsTermColors = { "154", "121", "211", "137", "214", "222" }
vim.g.interestingWordsGUIColors = { "#8CCBEA", "#A4E57E", "#FFDB72", "#FF7272", "#FFB3FF", "#9999FF" }

vim.opt.wrap = true
vim.opt.list = true
vim.opt.listchars = { space = "·" }
-- 设置剪贴板
vim.opt.clipboard = vim.env.SSH_CONNECTION and "" or "unnamedplus"
-- 显示行号
vim.opt.number = true
vim.opt.relativenumber = true
-- 显示光标所在位置的行号和列号
vim.opt.ruler = true
-- 高亮光标所在行
vim.opt.cursorline = true
-- 隐藏鼠标指针
vim.opt.mousehide = true
-- 设置帮助语言为中文
vim.opt.helplang = "ch"
-- 设置鼠标可用
vim.opt.mouse = "a"
-- 设置显示正在输入的命令
vim.opt.showcmd = true
-- 不使用缓存文件
vim.opt.backup = false
vim.opt.swapfile = false
-- 快速的响应时间
vim.opt.updatetime = 300
-- 打开命令菜单的补全
vim.opt.wildmenu = true
vim.opt.wildmode = "longest:list,full"
-- 关闭高亮搜索
vim.opt.hlsearch = false
-- 设置字符编码
vim.opt.encoding = "utf-8"
-- 倒数第二行显示状态行
vim.opt.laststatus = 2
-- 设置tab为2个空格
vim.opt.tabstop = 2
vim.opt.expandtab = true
-- 设置缩进为2个空格
vim.opt.shiftwidth = 2
-- 设置折叠方式为手动
vim.opt.foldmethod = "manual"

vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = { "*.xpu" },
  command = "set filetype=cuda",
})
