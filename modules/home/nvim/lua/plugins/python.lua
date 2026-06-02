return {
  -- Fix noice.nvim with Neovim 0.11+ (treesitter cmdline crash)
  {
    "folke/noice.nvim",
    opts = {
      cmdline = {
        format = {
          cmdline = { lang = "" },
          search_down = { lang = "" },
          search_up = { lang = "" },
          filter = { lang = "" },
          lua = { lang = "" },
        },
      },
    },
  },

  -- Use basedpyright instead of pyright (better type checking)
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.servers.basedpyright = {
        enabled = true,
        settings = {
          basedpyright = {
            typeCheckingMode = "standard",
          },
        },
      }
      -- Disable default pyright
      opts.servers.pyright = { enabled = false }
    end,
  },

  -- Ensure ruff is set up for formatting + linting
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      opts.formatters_by_ft.python = { "ruff_format", "ruff" }
    end,
  },
}
