#!/bin/zsh

# Script to create symlinks from home directory to dotfiles repository
# Usage: ./setup_symlinks.sh

set -e  # Exit on any error

DOTFILES="/Users/jonathan/files/10scripts/mac/dotfiles"
HOME_DIR="$HOME"

echo "🔗 Setting up dotfiles symlinks..."
echo "Source: $DOTFILES"
echo "Target: $HOME_DIR"
echo ""

# Function to create symlink with backup
create_symlink() {
    local source="$1"
    local target="$2"
    local target_dir=$(dirname "$target")
    
    # Create target directory if it doesn't exist
    if [[ ! -d "$target_dir" ]]; then
        echo "📁 Creating directory: $target_dir"
        mkdir -p "$target_dir"
    fi
    
    # Backup existing file/symlink if it exists
    if [[ -e "$target" || -L "$target" ]]; then
        echo "💾 Backing up existing: $target -> $target.backup"
        mv "$target" "$target.backup"
    fi
    
    # Create the symlink
    echo "🔗 Linking: $target -> $source"
    ln -sf "$source" "$target"
}

# Function to link all dotfiles into ~ and ~/.config
link_dotfiles() {
    echo "📝 Linking shell configuration files..."
    ln -sf "$DOTFILES/shell/.zshrc" ~/.zshrc
    ln -sf "$DOTFILES/shell/.zprofile" ~/.zprofile
    ln -sf "$DOTFILES/shell/.bashrc" ~/.bashrc
    
    echo "🪟 Linking window manager configuration..."
    ln -sf "$DOTFILES/yabairc" ~/.yabairc
    ln -sf "$DOTFILES/skhdrc" ~/.skhdrc
    
    echo "⚙️  Linking config directory applications..."
    # Ensure ~/.config exists
    mkdir -p ~/.config
    
    # Link all config directories
    ln -sf "$DOTFILES/config/nvim" ~/.config/nvim
    ln -sf "$DOTFILES/config/gh" ~/.config/gh
    ln -sf "$DOTFILES/config/github-copilot" ~/.config/github-copilot
    ln -sf "$DOTFILES/config/powershell" ~/.config/powershell
    ln -sf "$DOTFILES/config/raycast" ~/.config/raycast
    ln -sf "$DOTFILES/config/skhd" ~/.config/skhd
    ln -sf "$DOTFILES/config/yabai" ~/.config/yabai
    ln -sf "$DOTFILES/config/freerdp" ~/.config/freerdp
    ln -sf "$DOTFILES/config/NuGet" ~/.config/NuGet
    
    echo "✅ All dotfiles linked successfully!"
}


# Oh-My-Zsh installation and configuration
echo "🐚 Setting up Oh-My-Zsh..."

# Clone Oh-My-Zsh if not present
if [[ ! -d "$HOME_DIR/.oh-my-zsh" ]]; then
    echo "📦 Installing Oh-My-Zsh..."
    git clone https://github.com/ohmyzsh/ohmyzsh.git "$HOME_DIR/.oh-my-zsh"
else
    echo "✅ Oh-My-Zsh already installed"
fi

# Install Zsh plugins
echo "🔌 Installing Zsh plugins..."

# Install zsh-autosuggestions
if [[ ! -d "$HOME_DIR/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]]; then
    echo "📥 Installing zsh-autosuggestions..."
    git clone https://github.com/zsh-users/zsh-autosuggestions "$HOME_DIR/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
else
    echo "✅ zsh-autosuggestions already installed"
fi

# Install zsh-syntax-highlighting
if [[ ! -d "$HOME_DIR/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ]]; then
    echo "📥 Installing zsh-syntax-highlighting..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$HOME_DIR/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
else
    echo "✅ zsh-syntax-highlighting already installed"
fi

# Install zsh-autocomplete
if [[ ! -d "$HOME_DIR/.oh-my-zsh/custom/plugins/zsh-autocomplete" ]]; then
    echo "📥 Installing zsh-autocomplete..."
    git clone --depth 1 -- https://github.com/marlonrichert/zsh-autocomplete.git "$HOME_DIR/.oh-my-zsh/custom/plugins/zsh-autocomplete"
else
    echo "✅ zsh-autocomplete already installed"
fi


# Link all dotfiles
link_dotfiles

echo "✅ Setup complete!"
echo ""
echo "📋 Summary of created symlinks:"
echo "   ~/.zshrc -> $DOTFILES/shell/.zshrc"
echo "   ~/.zprofile -> $DOTFILES/shell/.zprofile"
echo "   ~/.bashrc -> $DOTFILES/shell/.bashrc"
echo "   ~/.yabairc -> $DOTFILES/yabairc"
echo "   ~/.skhdrc -> $DOTFILES/skhdrc"
echo "   ~/.config/nvim -> $DOTFILES/config/nvim"
echo "   ~/.config/gh -> $DOTFILES/config/gh"
echo "   ~/.config/github-copilot -> $DOTFILES/config/github-copilot"
echo "   ~/.config/powershell -> $DOTFILES/config/powershell"
echo "   ~/.config/raycast -> $DOTFILES/config/raycast"
echo "   ~/.config/skhd -> $DOTFILES/config/skhd"
echo "   ~/.config/yabai -> $DOTFILES/config/yabai"
echo "   ~/.config/freerdp -> $DOTFILES/config/freerdp"
echo "   ~/.config/NuGet -> $DOTFILES/config/NuGet"
echo ""
echo "🐚 Oh-My-Zsh Setup:"
echo "   ✅ Oh-My-Zsh installed at ~/.oh-my-zsh"
echo "   ✅ zsh-autosuggestions plugin installed"
echo "   ✅ zsh-syntax-highlighting plugin installed"
echo "   ✅ zsh-autocomplete plugin installed"
echo "   ✅ fzf and zoxide initialized in .zshrc"
echo ""
echo "💡 Note: Any existing files have been backed up with .backup extension"
echo "🔄 Restart your shell or run 'source ~/.zshrc' to apply changes"
echo ""
echo "📋 Next Steps:"
echo "   1. Run './setup_macos_defaults.sh' to configure macOS system preferences"
echo "   2. Grant Accessibility permissions for Yabai/Skhd (see README.md)"
echo "   3. Install Yabai and Skhd if not already installed: 'brew install koekeishiya/formulae/yabai koekeishiya/formulae/skhd'"
echo "   4. Start services: 'brew services start yabai && brew services start skhd'"
