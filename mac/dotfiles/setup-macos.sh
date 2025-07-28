#!/usr/bin/env bash

set -euo pipefail

# macOS Setup Script
# 
# This script sets up a new macOS system with essential tools and configurations.
# Run this script after a fresh macOS installation or when setting up a new machine.
#
# Usage:
#   ./setup-macos.sh
#
# What this script does:
#   - Installs Homebrew package manager
#   - Installs essential command-line packages
#   - Installs GUI applications via casks
#   - Creates symlinks for configuration files
#   - Configures shell environment (zsh)
#
# Prerequisites:
#   - Command Line Tools for Xcode should be installed
#   - Run: xcode-select --install
#

echo "Starting macOS setup..."

# =============================================================================
# Homebrew Installation
# =============================================================================
echo "Installing Homebrew..."

if ! command -v brew >/dev/null; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add Homebrew to PATH for Apple Silicon Macs
    if [[ $(uname -m) == "arm64" ]]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
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
for config_dir in nvim powershell gh skhd yabai; do
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

# Basic zsh configuration (only if dotfiles .zshrc wasn't used)
if [ ! -L ~/.zshrc ] && [ ! -f ~/.zshrc.backup ]; then
    if [ -f ~/.zshrc ]; then
        cp ~/.zshrc ~/.zshrc.backup
        echo "Backed up existing .zshrc"
    fi
    
    # Add basic configurations to .zshrc if not already present
    if ! grep -q "# Custom configurations" ~/.zshrc 2>/dev/null; then
        cat >> ~/.zshrc << 'EOF'

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
# Cleanup
# =============================================================================
echo "Cleaning up..."
brew cleanup

echo ""
echo "macOS setup completed successfully!"
echo ""
echo "Next steps:"
echo "  1. Restart your terminal or run: source ~/.zshrc"
echo "  2. Configure your dotfiles symlinks in the script if needed"
echo "  3. Install any additional applications manually"
echo "  4. Configure system preferences as desired"
echo ""
echo "Happy coding!"
