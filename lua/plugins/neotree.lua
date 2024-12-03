return {
  "nvim-neo-tree/neo-tree.nvim",
  keys = {
    { "<leader>'", "<cmd>Neotree toggle<cr>", desc = "NeoTree" },
  },
  opts = {
    window = {
      position = "left",
      width = 30,
      mappings = {
        ["o"] = "open",
        ["p"] = "close_node",
      },
    },
  },
}
