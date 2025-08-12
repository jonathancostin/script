---


You are to create a production-ready Neovim plugin called "finaltodo" that integrates seamlessly with LazyVim.
The plugin is a highly configurable TODO item tracker for developers who want to manage tasks directly inside Neovim.

The plugin must be written in Lua, follow Neovim plugin best practices, and be structured for maintainability.
It must be robust, performant, and ready for real-world use in large codebases.

---

## Functional Requirements

### 1. Search Scope
- By default, search in the current working directory (CWD).
- Allow user-defined "search shortcuts" in `search_dirs` config to quickly search other directories.

### 2. Pattern Matching
- Use **full regex** matching by default.
- Allow user to define patterns in `setup()` config.
- Initial defaults:
  ```lua
  patterns = { "TODO", "FIXME", "- %[ %]", "- %[x%]" }
  ```

### 3. UI Layout
- Dashboard is a **full tab page** (not floating).
- Single list view with thin rows.
- Each row shows:
  - Status (open/closed)
  - File path (relative)
  - Line number
  - Matched text
- Navigation:
  - `j/k` to move
  - `<CR>` to jump to file/line
- Filtering:
  - Open only
  - Closed only
  - All items

### 4. Task Editing
- Toggling a checkbox in the dashboard:
  - Edits the original file in place.
  - Saves the file immediately.
  - Raises an error if more than 1 line changes from its previous version.

### 5. Ignore Rules
- Automatically respect `.gitignore` in search directories.
- Allow manual ignore list in config:
  ```lua
  ignore_dirs = { "node_modules", ".git", "dist" }
  ```

### 6. GitHub Repo Creation
- On first run, prompt to create a **private GitHub repo** for the project.
- Sync the **entire project files** (not just `.finaltodo`).
- Require **manual push** (no auto-push).
- Use GitHub CLI (`gh`) if available.
- If repo exists, allow manual sync from within Neovim.

### 7. Keybindings
Provide a **full set of default keymaps** (user-overridable):
- `<leader>ft` → Open dashboard
- `<leader>fn` → New TODO in current file
- `<leader>fr` → Refresh list
- `<leader>fo` → Filter open
- `<leader>fc` → Filter closed
- `<leader>fa` → Show all
- `<leader>fx` → Toggle checkbox

### 8. Ripgrep Integration
- Use `ripgrep` for searching.
- Hybrid approach:
  - Cache results for speed.
  - Still run `ripgrep` every time dashboard opens to ensure freshness.

### 9. Task Creation
- New TODOs are inserted at the cursor in the current file.

### 10. Multi-Project Support
- If launched in CWD → search only that project.
- If launched from a shortcut → search in that configured directory.

---

## Technical Requirements

- Written in **Lua**.
- No external dependencies except:
  - `ripgrep` (required)
  - `gh` CLI (optional, for GitHub integration)
- Must work in Kitty, Ghostty, and tmux environments.
- Must be performant for large codebases.
- Code must be modular and split into:
  - `lua/finaltodo/init.lua` (entry point, setup)
  - `lua/finaltodo/config.lua` (default config)
  - `lua/finaltodo/ui.lua` (dashboard UI)
  - `lua/finaltodo/search.lua` (ripgrep integration)
  - `lua/finaltodo/git.lua` (repo creation/sync)
  - `lua/finaltodo/actions.lua` (toggle, filter, jump)
- Include a `README.md` with:
  - Installation instructions (LazyVim + manual)
  - Configuration examples
  - Keymap reference
  - GitHub integration guide
- Code must be formatted consistently (Prettier-style Lua formatting).
- Include error handling for:
  - Missing `ripgrep`
  - Missing `gh` CLI when GitHub sync is requested
  - File write conflicts when toggling tasks

---

## LazyVim Integration
Provide a LazyVim plugin spec:
```lua
{
  "username/finaltodo",
  config = function()
    require("finaltodo").setup({
      search_dirs = { "~/projects" },
      ignore_dirs = { "node_modules", ".git" },
      patterns = { "TODO", "- %[ %]" }
    })
  end
}
```

---

## Deliverables
1. Fully functional Neovim plugin in Lua.
2. Modular file structure as described.
3. LazyVim integration spec.
4. README.md with full documentation.
5. Example config file.
6. Example `.gitignore` handling.
7. GitHub CLI integration for repo creation and sync.

---

## Development Notes
- Use idiomatic Lua and Neovim API.
- Avoid blocking UI operations — use async jobs for `ripgrep` and GitHub CLI calls.
- Ensure dashboard UI updates without requiring a Neovim restart.
- Write code as if it will be maintained by other developers — clear naming, comments, and separation of concerns.
```

---
