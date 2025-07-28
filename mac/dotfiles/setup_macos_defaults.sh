#!/bin/zsh

# Script to configure macOS system preferences and defaults
# Usage: ./setup_macos_defaults.sh

set -e  # Exit on any error

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

echo ""
echo "📋 Summary of changes applied:"
echo "   • Dock: Auto-hide enabled, recent apps hidden, minimize to application"
echo "   • Finder: Show all extensions, path bar, and status bar enabled"
echo "   • Screenshots: Saved to ~/Screenshots as PNG without shadows"
echo "   • Mission Control: Disable rearranging spaces, faster animations"
echo "   • Trackpad: Tap to click enabled"
echo "   • Keyboard: Faster key repeat, disable press and hold"
echo "   • Spaces: Don't span displays (better for Yabai)"
echo ""
echo "⚠️  IMPORTANT: You still need to manually grant Accessibility permissions!"
echo "   1. Open System Preferences → Security & Privacy → Privacy → Accessibility"
echo "   2. Add Yabai and Skhd to the list and enable them"
echo "   3. You may need to logout/restart for all changes to take effect"
