return {
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "clangd",
        "ruff",
        "pyright",
        "shellcheck",
        "shfmt",
        "stylua",
      },
    },
  },
}
