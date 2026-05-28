return {
  {
    "neovim/nvim-lspconfig",
    init = function()
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("disable_clangd_semantic_tokens", { clear = true }),
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if not client or client.name ~= "clangd" then
            return
          end

          client.server_capabilities.semanticTokensProvider = nil
          if vim.lsp.semantic_tokens then
            pcall(vim.lsp.semantic_tokens.stop, args.buf, client.id)
          end
        end,
      })
    end,
  },
}
