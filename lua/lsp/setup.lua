-- the servers that should be automatically installed
local lsp_servers = {
	"sumneko_lua",
	"pyright",
	"jsonls",
	"bashls",
	"cmake",
	"clangd",
}

require("mason").setup({
	ui = {
		icons = {
			package_installed = "✓",
			package_pending = "➜",
			package_uninstalled = "✗",
		},
	},
})

require("mason-lspconfig").setup({
	ensure_installed = lsp_servers,
})

local lsp_server_configs = {
	sumneko_lua = require("lsp/sumneko_lua"), -- /lua/lsp/lua
}

local lspconfig = require("lspconfig")

local default_on_attach = function(client, bufnr)
	client.server_capabilities.documentFormattingProvider = false
	client.server_capabilities.document_range_formatting = false
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
