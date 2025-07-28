#!/bin/zsh

# Alternative script using GNU Stow for dotfiles management
# This approach requires restructuring the dotfiles to follow Stow conventions
# Usage: ./setup_with_stow.sh

set -e

DOTFILES_DIR="/Users/jonathan/files/10scripts/mac/dotfiles"
STOW_DIR="$DOTFILES_DIR/stow_packages"

echo "📦 Setting up dotfiles with GNU Stow..."
echo "Note: This creates a stow-compatible structure in $STOW_DIR"
echo ""

# Create stow packages directory
mkdir -p "$STOW_DIR"

# Create shell package
echo "🐚 Creating shell package..."
mkdir -p "$STOW_DIR/shell"
ln -sf "$DOTFILES_DIR/shell/.zshrc" "$STOW_DIR/shell/.zshrc" 2>/dev/null || cp "$DOTFILES_DIR/shell/.zshrc" "$STOW_DIR/shell/.zshrc"
ln -sf "$DOTFILES_DIR/shell/.zprofile" "$STOW_DIR/shell/.zprofile" 2>/dev/null || cp "$DOTFILES_DIR/shell/.zprofile" "$STOW_DIR/shell/.zprofile"
ln -sf "$DOTFILES_DIR/shell/.bashrc" "$STOW_DIR/shell/.bashrc" 2>/dev/null || cp "$DOTFILES_DIR/shell/.bashrc" "$STOW_DIR/shell/.bashrc"

# Create window manager package
echo "🪟 Creating window manager package..."
mkdir -p "$STOW_DIR/wm"
ln -sf "$DOTFILES_DIR/yabairc" "$STOW_DIR/wm/.yabairc" 2>/dev/null || cp "$DOTFILES_DIR/yabairc" "$STOW_DIR/wm/.yabairc"
ln -sf "$DOTFILES_DIR/skhdrc" "$STOW_DIR/wm/.skhdrc" 2>/dev/null || cp "$DOTFILES_DIR/skhdrc" "$STOW_DIR/wm/.skhdrc"

# Create config package
echo "⚙️  Creating config package..."
mkdir -p "$STOW_DIR/config-apps/.config"
for app in nvim gh github-copilot powershell raycast skhd yabai freerdp NuGet; do
    if [[ -d "$DOTFILES_DIR/config/$app" ]]; then
        ln -sf "$DOTFILES_DIR/config/$app" "$STOW_DIR/config-apps/.config/$app" 2>/dev/null || cp -r "$DOTFILES_DIR/config/$app" "$STOW_DIR/config-apps/.config/$app"
    fi
done

echo ""
echo "📋 Stow packages created. You can now use:"
echo "   cd $STOW_DIR"
echo "   stow shell      # Install shell configs"
echo "   stow wm         # Install window manager configs"  
echo "   stow config-apps # Install config directory apps"
echo ""
echo "Or install all at once:"
echo "   cd $STOW_DIR && stow *"
echo ""
echo "To uninstall a package:"
echo "   cd $STOW_DIR && stow -D shell"
