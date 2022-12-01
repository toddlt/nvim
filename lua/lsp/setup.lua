-- the servers that should be automatically installed
local lsp_servers = {
	"sumneko_lua",
	"gopls",
	"pyright",
	"jsonls",
	"html",
	"bashls",
	"tsserver",
}
-- using plug "nvim-lsp-installer" to ensure the installation
-- should before the lsp config
require("nvim-lsp-installer").setup({
	ensure_installed = lsp_servers,
	automatic_installation = true,
	ui = {
		icons = {
			server_installed = "✓",
			server_pending = "➜",
			server_uninstalled = "✗",
		},
	},
})
-- 需要特殊配置的lsp server
-- https://github.com/williamboman/nvim-lsp-installer#available-lsps
-- { key: 语言 value: 配置文件 }
local lsp_server_configs = {
	sumneko_lua = require("lsp.lua"), -- /lua/lsp/lua
}

local lspconfig = require("lspconfig")

local default_on_attach = function(client, bufnr)
	client.server_capabilities.documentFormattingProvider = false
	client.resolved_capabilities.document_range_formatting = false
	local function buf_set_keymap(...)
		vim.api.nvim_buf_set_keymap(bufnr, ...)
	end
	-- 绑定快捷键
	require("keybindings").mapLSP(buf_set_keymap)
	vim.cmd("autocmd BufWritePre <buffer> lua vim.lsp.buf.formatting_sync()")
end

for _, server in pairs(lsp_servers) do
	local options = lsp_server_configs[server]
	if options == nil then
		lspconfig[server].setup({
			on_attach = default_on_attach,
			flags = {
				debounce_text_changes = 150,
			},
		})
	else
		lspconfig[server].setup(options)
	end
end
