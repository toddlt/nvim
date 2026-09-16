return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown" },
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-mini/mini.icons",
    },
    ---@module "render-markdown"
    ---@type render.md.UserConfig
    opts = {
      preset = "none",
      heading = {
        sign = false,
        icons = { "▌ ", "▌ ", "▎ ", "▎ ", "▏ ", "▏ " },
        width = "block",
        left_pad = { 1, 1, 0 },
        right_pad = { 1, 1, 0 },
        border = false,
        backgrounds = {
          "RenderMarkdownH1Bg",
          "RenderMarkdownH2Bg",
          "Normal",
        },
      },
      code = {
        sign = false,
        width = "block",
        border = "thin",
        left_pad = 1,
        right_pad = 1,
      },
      pipe_table = {
        preset = "round",
        cell = "trimmed",
        padding = 0,
        min_width = 1,
        border_virtual = true,
      },
      quote = {
        repeat_linebreak = true,
      },
      completions = {
        lsp = { enabled = true },
      },
    },
    config = function(_, opts)
      local render_markdown = require("render-markdown")
      render_markdown.setup(opts)
      Snacks.toggle({
        name = "Render Markdown",
        get = render_markdown.get,
        set = render_markdown.set,
      }):map("<leader>um")
    end,
  },
}
