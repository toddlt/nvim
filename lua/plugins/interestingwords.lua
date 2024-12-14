return {
  "lfv89/vim-interestingwords",
  keys = {
    { "<leader>h", "<cmd>call InterestingWords('n')<cr>", desc = "highlight word" },
    { "<leader>c", "<cmd>call UncolorAllWords()<cr>", desc = "clear highlight" },
    { "n", "<cmd>call WordNavigation('forward')<cr>", desc = "forward highlight" },
    { "N", "<cmd>call WordNavigation('backward')<cr>", desc = "backward highlight" },
  },
  --   vim.g.interestingWordsTermColors = { "154", "121", "211", "137", "214", "222" }
  --   vim.g.interestingWordsGUIColors = { "#8CCBEA", "#A4E57E", "#FFDB72", "#FF7272", "#FFB3FF", "#9999FF" },
}
