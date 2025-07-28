#!/usr/bin/env bash

set -euo pipefail

# Combined macOS Setup Script
#
# This script sets up a new macOS system with essential tools and configurations.
# It includes Homebrew installation, package installations, symlink creations, and system settings.
#
# Usage:
#   ./combined-setup.sh
#
# Prerequisites:
#   - Command Line Tools for Xcode should be installed
#   - Run: xcode-select --install
#

echo "Starting combined macOS setup..."

# =============================================================================
# Homebrew Installation
# =============================================================================
echo "Installing Homebrew..."

if ! command -v brew >/dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Add Homebrew to PATH for Apple Silicon Macs
  if [[ $(uname -m) == "arm64" ]]; then
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >>~/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
else
  echo "Homebrew already installed"
fi

# Update Homebrew
brew update

# =============================================================================
# Essential Packages
# =============================================================================
echo "Installing essential command-line packages..."

PACKAGES=(eza fzf gh go lazygit neovim oh-my-posh skhd yabai zoxide nmap stow)

for package in "${PACKAGES[@]}"; do
  if brew list "$package" >/dev/null 2>&1; then
    echo "$package is already installed"
  else
    echo "Installing $package..."
    brew install "$package"
  fi
done

# =============================================================================
# GUI Applications (Casks)
# =============================================================================
echo "Installing GUI applications..."

CASKS=(font-hack-nerd-font ghostty powershell stats betterdisplay)

for cask in "${CASKS[@]}"; do
  if brew list --cask "$cask" >/dev/null 2>&1; then
    echo "$cask is already installed"
  else
    echo "Installing $cask..."
    brew install --cask "$cask"
  fi
done

# =============================================================================
# Symlinks for Configuration Files
# =============================================================================
echo "Creating symlinks for configuration files..."

# Create directories if they don't exist
mkdir -p ~/.config

DOTFILES_DIR="$HOME/files/10scripts/mac/dotfiles"

# Create symlinks for shell configuration files
if [ -f "$DOTFILES_DIR/shell/.zshrc" ]; then
  ln -sf "$DOTFILES_DIR/shell/.zshrc" ~/.zshrc
  echo "Created symlink for .zshrc"
fi
if [ -f "$DOTFILES_DIR/shell/.bashrc" ]; then
  ln -sf "$DOTFILES_DIR/shell/.bashrc" ~/.bashrc
  echo "Created symlink for .bashrc"
fi
if [ -f "$DOTFILES_DIR/shell/.zprofile" ]; then
  ln -sf "$DOTFILES_DIR/shell/.zprofile" ~/.zprofile
  echo "Created symlink for .zprofile"
fi

# Create symlinks for window manager configs
if [ -f "$DOTFILES_DIR/yabairc" ]; then
  ln -sf "$DOTFILES_DIR/yabairc" ~/.yabairc
  echo "Created symlink for .yabairc"
fi
if [ -f "$DOTFILES_DIR/skhdrc" ]; then
  ln -sf "$DOTFILES_DIR/skhdrc" ~/.skhdrc
  echo "Created symlink for .skhdrc"
fi

# Create symlinks for config directories
for config_dir in nvim powershell gh skhd yabai github-copilot raycast freerdp NuGet; do
  if [ -d "$DOTFILES_DIR/config/$config_dir" ]; then
    ln -sf "$DOTFILES_DIR/config/$config_dir" ~/.config/
    echo "Created symlink for $config_dir config"
  fi
done

echo "Symlink creation completed"

# =============================================================================
# Shell Configuration (zsh)
# =============================================================================
echo "Configuring zsh shell..."

# Set zsh as default shell if not already
if [[ $SHELL != */zsh ]]; then
  echo "Setting zsh as default shell..."
  chsh -s $(which zsh)
fi

# Install Oh My Zsh if not already installed
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "Installing Oh My Zsh..."
  sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
  echo "Oh My Zsh already installed"
fi

# Install Zsh plugins
echo "🔌 Installing Zsh plugins..."

# Install zsh-autosuggestions
if [[ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]]; then
  echo "📥 Installing zsh-autosuggestions..."
  git clone https://github.com/zsh-users/zsh-autosuggestions "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
else
  echo "✅ zsh-autosuggestions already installed"
fi

# Install zsh-syntax-highlighting
if [[ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ]]; then
  echo "📥 Installing zsh-syntax-highlighting..."
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
else
  echo "✅ zsh-syntax-highlighting already installed"
fi

# Install zsh-autocomplete
if [[ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-autocomplete" ]]; then
  echo "📥 Installing zsh-autocomplete..."
  git clone --depth 1 -- https://github.com/marlonrichert/zsh-autocomplete.git "$HOME/.oh-my-zsh/custom/plugins/zsh-autocomplete"
else
  echo "✅ zsh-autocomplete already installed"
fi

# Basic zsh configuration (only if dotfiles .zshrc wasn't used)
if [ ! -L ~/.zshrc ] && [ ! -f ~/.zshrc.backup ]; then
  if [ -f ~/.zshrc ]; then
    cp ~/.zshrc ~/.zshrc.backup
    echo "Backed up existing .zshrc"
  fi

  # Add basic configurations to .zshrc if not already present
  if ! grep -q "# Custom configurations" ~/.zshrc 2>/dev/null; then
    cat >>~/.zshrc <<'EOF'

# Custom configurations
export EDITOR=vim
export PATH="/usr/local/bin:$PATH"

# Aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'

# Homebrew
if [[ $(uname -m) == "arm64" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi
EOF
    echo "Added custom configurations to .zshrc"
  fi
else
  echo "Using dotfiles .zshrc or backup already exists, skipping basic configuration"
fi

# =============================================================================
# macOS System Preferences
# =============================================================================
echo "🍎 Configuring macOS System Preferences..."
echo ""

# Dock settings
echo "⚙️  Configuring Dock settings..."
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock minimize-to-application -bool true
defaults write com.apple.dock tilesize -int 48
defaults write com.apple.dock orientation -string "bottom"

# Finder settings
echo "📁 Configuring Finder settings..."
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# Screenshot settings
echo "📸 Configuring Screenshot settings..."
mkdir -p ~/Screenshots
defaults write com.apple.screencapture location ~/Screenshots
defaults write com.apple.screencapture type -string "png"
defaults write com.apple.screencapture disable-shadow -bool true

# Mission Control settings
echo "🖥️  Configuring Mission Control settings..."
defaults write com.apple.dock mru-spaces -bool false
defaults write com.apple.dock expose-animation-duration -float 0.1
defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false

# Trackpad settings
echo "🖱️  Configuring Trackpad settings..."
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# Keyboard settings
echo "⌨️  Configuring Keyboard settings..."
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# Menu bar settings
echo "📋 Configuring Menu Bar settings..."
defaults write com.apple.systemuiserver menuExtras -array \
  "/System/Library/CoreServices/Menu Extras/Bluetooth.menu" \
  "/System/Library/CoreServices/Menu Extras/AirPort.menu" \
  "/System/Library/CoreServices/Menu Extras/Battery.menu" \
  "/System/Library/CoreServices/Menu Extras/Clock.menu"

# Window management settings (for Yabai)
echo "🪟 Configuring Window Management settings..."
defaults write com.apple.spaces spans-displays -bool false
defaults write com.apple.dock workspaces-auto-swoosh -bool false

echo ""
echo "✅ macOS defaults configured successfully!"
echo ""
echo "🔄 Restarting affected services..."
killall Dock
killall Finder
killall SystemUIServer

# =============================================================================
# Cleanup
# =============================================================================
echo "Cleaning up..."
brew cleanup

echo ""
echo "🎉 macOS setup completed successfully!"
echo ""
echo "📋 Summary of what was configured:"
echo "   ✅ Homebrew package manager installed/updated"
echo "   ✅ Essential command-line packages installed"
echo "   ✅ GUI applications installed via casks"
echo "   ✅ Dotfiles symlinked from $DOTFILES_DIR"
echo "   ✅ Oh-My-Zsh installed with plugins"
echo "   ✅ macOS system preferences optimized"
echo ""
echo "⚠️  IMPORTANT: Manual steps required:"
echo "   1. Grant Accessibility permissions for Yabai/Skhd:"
echo "      System Preferences → Security & Privacy → Privacy → Accessibility"
echo "   2. Start window manager services:"
echo "      brew services start yabai && brew services start skhd"
echo ""
echo "🔄 Next steps:"
echo "   1. Restart your terminal or run: source ~/.zshrc"
echo "   2. Verify all applications are working correctly"
echo "   3. Customize configurations as needed"
echo ""
echo "Happy coding! 🚀"
