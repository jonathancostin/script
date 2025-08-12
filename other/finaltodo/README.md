# FinalTodo

A production-ready Neovim plugin for managing TODO items directly inside your editor. Built for developers who want seamless task tracking integrated with their workflow.

## Features

- 🔍 **Fast Search**: Powered by ripgrep for blazing-fast TODO/FIXME detection
- 📋 **Full Tab Dashboard**: Clean, focused interface for managing tasks
- ✅ **Interactive Toggling**: Toggle checkboxes directly from the dashboard
- 🔄 **Live Updates**: Automatic refresh on file changes
- 🐙 **GitHub Integration**: Optional GitHub repository sync for your tasks
- ⚡ **LazyVim Ready**: Designed for seamless LazyVim integration
- 🎯 **Smart Filtering**: View open, closed, or all tasks instantly

## Requirements

- Neovim >= 0.8.0
- `ripgrep` (required)
- `gh` CLI (optional, for GitHub integration)

## Installation

### Using lazy.nvim (LazyVim)

```lua
{
  "username/finaltodo",
  dependencies = {},
  config = function()
    require("finaltodo").setup({
      -- your configuration
    })
  end,
  keys = {
    { "<leader>ft", "<cmd>FinalTodo<cr>", desc = "Open FinalTodo" },
    { "<leader>fn", function() require("finaltodo").create_todo() end, desc = "New TODO" },
  },
}
```

### Using packer.nvim

```lua
use {
  "username/finaltodo",
  config = function()
    require("finaltodo").setup()
  end
}
```

## Configuration

```lua
require("finaltodo").setup({
  -- Search directories (in addition to CWD)
  search_dirs = { "~/projects", "~/work" },
  
  -- Patterns to search for (regex)
  patterns = {
    "TODO",
    "FIXME",
    "HACK",
    "NOTE",
    "%- %[ %]",     -- Markdown checkboxes
    "%- %[x%]",     -- Completed checkboxes
  },
  
  -- Directories to ignore
  ignore_dirs = {
    "node_modules",
    ".git",
    "dist",
    "build",
  },
  
  -- Keybindings (all customizable)
  keymaps = {
    open_dashboard = "<leader>ft",
    new_todo = "<leader>fn",
    refresh = "<leader>fr",
    filter_open = "<leader>fo",
    filter_closed = "<leader>fc",
    show_all = "<leader>fa",
    toggle = "<leader>fx",
  },
  
  -- UI configuration
  ui = {
    relative_numbers = false,
    wrap = false,
    icons = {
      open = "[ ]",
      closed = "[x]",
      todo = "●",
      fixme = "✗",
    },
  },
  
  -- Caching for performance
  cache = {
    enabled = true,
    ttl = 5000,  -- milliseconds
  },
  
  -- GitHub integration
  github = {
    auto_create_repo = false,
    repo_name = nil,  -- auto-generated if nil
    private = true,
  },
})
```

## Usage

### Commands

- `:FinalTodo` - Open the dashboard
- `:FinalTodo refresh` - Refresh the task list
- `:FinalTodo open` - Show only open tasks
- `:FinalTodo closed` - Show only closed tasks
- `:FinalTodo all` - Show all tasks
- `:FinalTodo new` - Create a new TODO at cursor
- `:FinalTodo push` - Push changes to GitHub
- `:FinalTodo pull` - Pull changes from GitHub
- `:FinalTodo repo` - Create/connect GitHub repository
- `:FinalTodoSearch [dir]` - Search in specific directory

### Dashboard Keybindings

| Key | Action |
|-----|--------|
| `j`/`k` | Navigate up/down |
| `<CR>` | Jump to file/line |
| `x` | Toggle checkbox |
| `r` | Refresh list |
| `o` | Show open items only |
| `c` | Show closed items only |
| `a` | Show all items |
| `q` | Close dashboard |
| `?` | Show help |

### Global Keybindings (Default)

| Key | Action |
|-----|--------|
| `<leader>ft` | Open dashboard |
| `<leader>fn` | New TODO |
| `<leader>fr` | Refresh |
| `<leader>fo` | Filter open |
| `<leader>fc` | Filter closed |
| `<leader>fa` | Show all |
| `<leader>fx` | Toggle checkbox |

## GitHub Integration

FinalTodo can optionally sync your entire project to a private GitHub repository:

1. **First Run Setup**: If `auto_create_repo` is enabled, you'll be prompted to create a repo
2. **Manual Setup**: Run `:FinalTodo repo` to create/connect a repository
3. **Push Changes**: Use `:FinalTodo push` or `<leader>fp` to push
4. **Pull Changes**: Use `:FinalTodo pull` or `<leader>fl` to sync

### Requirements for GitHub Integration

- `gh` CLI must be installed and authenticated
- Project must be a git repository
- Internet connection for sync operations

## Pattern Examples

FinalTodo searches for various TODO patterns:

```lua
-- Standard comments
-- TODO: Implement this feature
-- FIXME: Bug in calculation
-- HACK: Temporary workaround
-- NOTE: Important information

-- Markdown checkboxes
- [ ] Uncompleted task
- [x] Completed task

-- Custom patterns (add your own)
patterns = {
  "REVIEW",
  "OPTIMIZE",
  "@todo",
}
```

## Performance

FinalTodo is optimized for large codebases:

- Uses ripgrep for fast searching
- Intelligent caching with configurable TTL
- Async operations prevent UI blocking
- Respects `.gitignore` automatically

## Troubleshooting

### Ripgrep not found

Install ripgrep:
```bash
# macOS
brew install ripgrep

# Ubuntu/Debian
apt-get install ripgrep

# Arch
pacman -S ripgrep
```

### GitHub sync not working

1. Install GitHub CLI: `brew install gh` or equivalent
2. Authenticate: `gh auth login`
3. Ensure project is a git repository: `git init`

### Tasks not updating

- Check if file is saved
- Try manual refresh with `r` in dashboard
- Clear cache with `:FinalTodo refresh`

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License - see LICENSE file for details

## Acknowledgments

- Built with ❤️ for the Neovim community
- Powered by ripgrep for blazing-fast searches
- Inspired by various TODO management plugins