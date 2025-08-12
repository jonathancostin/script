# finaltodo - Implementation Plan

## Overview
A production-ready Neovim plugin for managing TODO items directly within the editor, designed for LazyVim integration.

## Architecture

### Module Structure
- **init.lua**: Entry point, setup function, command registration
- **config.lua**: Default configuration and user config merging
- **search.lua**: Ripgrep integration with caching
- **ui.lua**: Dashboard rendering and buffer management
- **actions.lua**: Task operations (toggle, filter, jump)
- **git.lua**: GitHub repo creation and sync

### Key Design Decisions

1. **Full Tab Page UI**: Using a dedicated tab page for the dashboard provides maximum screen real estate
2. **Ripgrep Integration**: Leveraging ripgrep for speed with intelligent caching
3. **Immediate File Saving**: When toggling tasks, save immediately to prevent data loss
4. **Modular Architecture**: Each module has a single responsibility for maintainability

## Implementation Order

1. **Core Setup** (config.lua, init.lua)
   - Define default configuration structure
   - Create setup function with config merging
   - Register commands and keymaps

2. **Search Engine** (search.lua)
   - Implement ripgrep wrapper with async execution
   - Add .gitignore respect
   - Build caching layer

3. **UI Layer** (ui.lua)
   - Create dashboard buffer and window
   - Implement list rendering
   - Add navigation keymaps

4. **Actions** (actions.lua)
   - Toggle checkbox functionality with file editing
   - Filter implementation (open/closed/all)
   - Jump to file/line

5. **Git Integration** (git.lua)
   - GitHub repo creation via gh CLI
   - Manual sync functionality

## Technical Considerations

### Performance
- Use vim.loop.spawn for async ripgrep calls
- Cache search results with TTL
- Batch UI updates to prevent flicker

### Error Handling
- Check for ripgrep availability on startup
- Graceful fallback if gh CLI not present
- Validate file changes when toggling (single line only)

### LazyVim Integration
- Provide lazy.nvim spec with default config
- Use standard LazyVim keybinding patterns
- Follow LazyVim UI conventions

## Testing Strategy
- Manual testing in real projects
- Edge cases: large codebases, binary files, symlinks
- Terminal compatibility: Kitty, Ghostty, tmux

## Configuration Schema
```lua
{
  search_dirs = {},           -- Additional search directories
  patterns = {                -- Default search patterns
    "TODO",
    "FIXME", 
    "- %[ %]",
    "- %[x%]"
  },
  ignore_dirs = {             -- Directories to ignore
    "node_modules",
    ".git",
    "dist"
  },
  keymaps = {                 -- Default keybindings
    open_dashboard = "<leader>ft",
    new_todo = "<leader>fn",
    refresh = "<leader>fr",
    filter_open = "<leader>fo",
    filter_closed = "<leader>fc",
    show_all = "<leader>fa",
    toggle = "<leader>fx"
  }
}
```

## File Structure
```
finaltodo/
├── lua/
│   └── finaltodo/
│       ├── init.lua
│       ├── config.lua
│       ├── search.lua
│       ├── ui.lua
│       ├── actions.lua
│       └── git.lua
├── README.md
└── docs/
    ├── plan.md
    └── CLAUDE.md
```