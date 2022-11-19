require("basic")

require("keybindings")

require("plugins")

require("colorscheme")

require("hop").setup()
require("lualine").setup({
	options = { theme = "nord" },
})

require("config.bufferline")
require("config.dashboard")
require("config.indent-blankline")
require("config.nvim-tree")
require("config.transparent")
require("config.treesitter")
require("config.vista")

require("lsp/setup")
require("lsp/nvim-cmp")
require("lsp/null-ls")
