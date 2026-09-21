return {
  {
    name = "agent-term",
    dir = vim.fn.stdpath("config") .. "/lua/locals/agent-term.nvim",
    main = "agent-term",
    lazy = false,
    opts = {
      shell = {
        enabled = true,
        -- command defaults to vim.o.shell; override it only for a specific environment.
        flags = { "-ic" },
      },
      -- Add another CLI here; the shared implementation does not need to change.
      agents = {
        claude = {
          command = { "claude" },
          key = "<leader>ac",
          order = 1,
          variants = {
            continue = { key = "<leader>cC", args = { "--continue" } },
            resume = { args = { "--resume" } },
          },
        },
        codex = {
          command = { "codex" },
          key = "<leader>ax",
          order = 2,
          variants = {},
        },
        ["deepseek-harness"] = {
          command = { "dst" },
          key = "<leader>ad",
          order = 3,
          variants = {},
        },
        antigravity = {
          command = { "agy" },
          key = "<leader>aa",
          order = 4,
          variants = {},
        },
      },
      window = {
        position = "float", -- botright, topleft, left, right, vertical, or float
        split_ratio = 0.7,
        enter_insert = true,
        hide_numbers = true,
        hide_signcolumn = true,
        float = {
          width = "80%",
          height = "80%",
          row = "center",
          col = "center",
          border = "rounded",
        },
      },
      refresh = {
        enable = true,
        updatetime = 100,
        timer_interval = 1000,
        show_notifications = true,
      },
      git = {
        use_git_root = true,
        multi_instance = true,
      },
      keymaps = {
        toggle = "<C-,>",
        select = "<leader>as",
        window_navigation = true,
        scrolling = true,
      },
    },
  },
}
