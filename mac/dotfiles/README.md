# macOS Dotfiles

A comprehensive collection of dotfiles and configuration scripts for macOS, including shell configurations, window management (Yabai/Skhd), and application-specific settings.

## 📁 Repository Structure

```
dotfiles/
├── README.md                    # This file
├── combined-setup.sh           # All-in-one setup script (RECOMMENDED)
├── setup_symlinks.sh           # Creates symlinks and installs plugins
├── setup_macos_defaults.sh     # Configures macOS system preferences
├── setup_with_stow.sh          # Alternative setup using GNU Stow
├── shell/                      # Shell configuration files
│   ├── .zshrc                  # Zsh configuration with Oh-My-Zsh
│   ├── .zprofile              # Zsh profile (login shell)
│   └── .bashrc                # Bash configuration
├── config/                     # Application configs (symlinked to ~/.config/)
│   ├── nvim/                  # Neovim configuration
│   ├── gh/                    # GitHub CLI configuration
│   ├── github-copilot/        # GitHub Copilot CLI settings
│   ├── powershell/            # PowerShell Core configuration
│   ├── raycast/               # Raycast settings
│   ├── skhd/                  # Hotkey daemon configuration
│   ├── yabai/                 # Window manager configuration
│   ├── freerdp/               # FreeRDP settings
│   └── NuGet/                 # NuGet configuration
├── themes/                     # Theme configurations
│   └── oh-my-posh/            # Oh-My-Posh themes
│       └── bubbles.omp.json   # Bubbles theme config
├── yabairc                     # Yabai window manager config (symlinked to ~/.yabairc)
├── skhdrc                      # Skhd hotkey config (symlinked to ~/.skhdrc)
└── .zshrc                      # Legacy zshrc (use shell/.zshrc instead)
```

## 🚀 Quick Setup

### Prerequisites

- macOS (tested on macOS 12+)
- Zsh shell (default on macOS)
- Git (for cloning repositories)
- Homebrew (recommended for installing packages)

### 🔥 Recommended: Complete Setup (New Computers)

**For setting up a new macOS computer**, use the all-in-one script that handles everything:

```bash
cd /Users/jonathan/files/10scripts/mac/dotfiles
chmod +x combined-setup.sh
./combined-setup.sh
```

This comprehensive script will:
- **Install Homebrew** (if not already installed)
- **Install essential CLI packages**: git, vim, curl, wget, tree, jq, htop, etc.
- **Install GUI applications**: Chrome, VSCode, iTerm2, Docker, Raycast, etc.
- **Install Oh-My-Zsh and plugins** (autosuggestions, syntax highlighting, autocomplete)
- **Create symlinks** for all shell configurations and dotfiles
- **Set up window management** (Yabai/Skhd configs)
- **Configure application configs** in `~/.config/`
- **Apply macOS system preferences** (Dock, Finder, screenshots, trackpad, etc.)
- **Backup existing files** with `.backup` extension

**Manual steps after running the script:**
1. Grant Accessibility permissions to Yabai and Skhd in System Preferences
2. Start the window manager services: `brew services start yabai && brew services start skhd`
3. Restart your terminal or run `source ~/.zshrc`

### Individual Setup Scripts (Advanced Users)

For users who prefer granular control or want to run parts separately:

#### Install Symlinks and Shell Plugins

```bash
chmod +x setup_symlinks.sh
./setup_symlinks.sh
```

#### Configure macOS System Preferences

```bash
chmod +x setup_macos_defaults.sh
./setup_macos_defaults.sh
```

### Alternative: GNU Stow Method

For users who prefer GNU Stow for dotfiles management:

```bash
# Install stow if not already installed
brew install stow

# Run the stow setup script
chmod +x setup_with_stow.sh
./setup_with_stow.sh

# Use stow to link packages
cd stow_packages
stow shell wm config-apps  # Install all packages
```

## 🔄 Updating Dotfiles and Re-syncing Symlinks

### Method 1: Re-run Setup Script

The simplest way to update and re-sync symlinks:

```bash
cd /Users/jonathan/files/10scripts/mac/dotfiles

# For complete refresh (includes Homebrew packages and apps)
./combined-setup.sh

# Or for just dotfiles and symlinks
./setup_symlinks.sh
```

The scripts are idempotent and will:
- Update existing symlinks
- Install missing packages/applications (combined script only)
- Install missing Oh-My-Zsh plugins
- Backup any conflicting files

### Method 2: Manual Updates

For individual file updates:

```bash
# Update a specific config
ln -sf /Users/jonathan/files/10scripts/mac/dotfiles/shell/.zshrc ~/.zshrc

# Update application configs
ln -sf /Users/jonathan/files/10scripts/mac/dotfiles/config/nvim ~/.config/nvim
```

### Method 3: Git-based Updates

If your dotfiles are in a Git repository:

```bash
cd /Users/jonathan/files/10scripts/mac/dotfiles
git pull origin main
./setup_symlinks.sh  # Re-sync after pulling changes
```

### Updating Oh-My-Zsh and Plugins

```bash
# Update Oh-My-Zsh
cd ~/.oh-my-zsh && git pull

# Update individual plugins
cd ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions && git pull
cd ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting && git pull
cd ~/.oh-my-zsh/custom/plugins/zsh-autocomplete && git pull
```

## 🔧 Troubleshooting

### Permission Issues

**Problem**: Scripts fail with permission denied errors.

**Solution**:
```bash
chmod +x combined-setup.sh setup_symlinks.sh setup_macos_defaults.sh setup_with_stow.sh
```

### Symlink Conflicts

**Problem**: "File exists" errors when creating symlinks.

**Solution**: The scripts automatically backup existing files, but you can manually resolve:
```bash
# Remove existing file/symlink
rm ~/.zshrc

# Re-run setup
./setup_symlinks.sh
```

### Oh-My-Zsh Installation Fails

**Problem**: Git clone fails or Oh-My-Zsh doesn't install properly.

**Solutions**:
```bash
# Manual Oh-My-Zsh installation
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Or using wget
sh -c "$(wget https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)"

# Then re-run the setup script
./setup_symlinks.sh
```

### Yabai/Skhd Not Working

**Problem**: Window management not functioning after setup.

**Solutions**:

1. **Install Yabai and Skhd**:
   ```bash
   brew install koekeishiya/formulae/yabai koekeishiya/formulae/skhd
   ```

2. **Grant Accessibility Permissions**:
   - Open System Preferences → Security & Privacy → Privacy → Accessibility
   - Add Yabai and Skhd to the list and enable them
   - You may need to add the actual binary paths:
     - `/opt/homebrew/bin/yabai` (Apple Silicon)
     - `/usr/local/bin/yabai` (Intel)

3. **Start Services**:
   ```bash
   brew services start yabai
   brew services start skhd
   ```

4. **Check Service Status**:
   ```bash
   brew services list | grep -E "(yabai|skhd)"
   ```

### Shell Changes Not Applied

**Problem**: New shell configuration doesn't take effect.

**Solutions**:
```bash
# Reload shell configuration
source ~/.zshrc

# Or restart terminal/start new shell session
exec zsh

# Check if symlinks are correct
ls -la ~/.zshrc ~/.zprofile
```

### Application Configs Not Loading

**Problem**: Application-specific configs in `~/.config/` not working.

**Solutions**:
```bash
# Verify symlinks exist
ls -la ~/.config/

# Check specific app config
ls -la ~/.config/nvim ~/.config/gh

# Manually recreate symlink if needed
ln -sf /Users/jonathan/files/10scripts/mac/dotfiles/config/nvim ~/.config/nvim
```

### Backup Files Cluttering Home Directory

**Problem**: Too many `.backup` files after running scripts multiple times.

**Solution**:
```bash
# List all backup files
find ~ -name "*.backup" -maxdepth 1

# Remove backup files (be careful!)
find ~ -name "*.backup" -maxdepth 1 -delete

# Or move them to a backup directory
mkdir ~/old_dotfiles_backups
find ~ -name "*.backup" -maxdepth 1 -exec mv {} ~/old_dotfiles_backups/ \;
```

### macOS Defaults Not Applied

**Problem**: System preferences don't change after running `setup_macos_defaults.sh`.

**Solutions**:
```bash
# Some changes require logout/restart
sudo shutdown -r now

# Or try killing specific services
killall Dock
killall Finder
killall SystemUIServer

# Check if defaults were set
defaults read com.apple.dock autohide
```

### Stow Method Issues

**Problem**: GNU Stow conflicts or doesn't create proper symlinks.

**Solutions**:
```bash
# Install stow if missing
brew install stow

# Remove conflicting files first
stow -D shell  # Remove existing package
rm ~/.zshrc    # Remove conflicting file
stow shell     # Re-install package

# Check stow status
stow -n shell  # Dry run to see what would happen
```

## 📋 Additional Notes

### Customization

- Edit files in the dotfiles directory; changes will be reflected immediately due to symlinks
- Add new applications by creating directories in `config/` and updating `setup_symlinks.sh`
- Modify `setup_macos_defaults.sh` to include additional system preferences

### Maintenance

- Regularly update Oh-My-Zsh and plugins for security and features
- Review and test macOS defaults after system updates
- Keep backup files until you're confident the new setup works correctly

### Dependencies

The setup scripts will attempt to install:
- Oh-My-Zsh framework
- zsh-autosuggestions plugin
- zsh-syntax-highlighting plugin  
- zsh-autocomplete plugin

Optional dependencies (install manually):
- Yabai: `brew install koekeishiya/formulae/yabai`
- Skhd: `brew install koekeishiya/formulae/skhd`
- GNU Stow: `brew install stow`
- Neovim: `brew install neovim`

For questions or issues, check the troubleshooting section above or review the script output for specific error messages.
