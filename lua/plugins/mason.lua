return {
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "clangd",
        "flake8",
        "pyright",
        "shellcheck",
        "shfmt",
        "stylua",
      },
    },
  },
}
