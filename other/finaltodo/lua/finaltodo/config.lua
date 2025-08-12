local M = {}

M.defaults = {
  search_dirs = {},
  patterns = {
    "TODO",
    "FIXME",
    "HACK",
    "NOTE",
    "PERF",
    "WARNING",
    "%- %[ %]",
    "%- %[x%]",
  },
  ignore_dirs = {
    "node_modules",
    ".git",
    "dist",
    "build",
    ".cache",
    ".next",
    ".nuxt",
    ".venv",
    "__pycache__",
    "target",
    "vendor",
  },
  keymaps = {
    open_dashboard = "<leader>ft",
    new_todo = "<leader>fn",
    refresh = "<leader>fr",
    filter_open = "<leader>fo",
    filter_closed = "<leader>fc",
    show_all = "<leader>fa",
    toggle = "<leader>fx",
  },
  ui = {
    width = "100%",
    height = "100%",
    relative_numbers = false,
    wrap = false,
    icons = {
      open = "[ ]",
      closed = "[x]",
      todo = "●",
      fixme = "✗",
      hack = "⚠",
      note = "ℹ",
      perf = "⚡",
      warning = "⚠",
    },
  },
  cache = {
    enabled = true,
    ttl = 5000,
  },
  github = {
    auto_create_repo = false,
    repo_name = nil,
    private = true,
  },
}

M.options = {}

function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})
  return M.options
end

function M.get()
  return M.options
end

return M