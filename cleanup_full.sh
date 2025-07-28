#!/bin/zsh

echo "🧹 BROWSER CACHE & DOWNLOADS CLEANUP"
echo "===================================="
echo ""
echo "This will delete:"
echo "  📁 Safari Cache (~4.0K)"
echo "  📁 Google/Chrome Cache (~3.1M)" 
echo "  📁 Downloads Folder (~11G, 31 items)"
echo ""
echo "⚠️  TOTAL: ~11G of data will be permanently deleted!"
echo ""

read "confirm?Are you sure you want to proceed? (y/N): "

if [[ $confirm =~ ^[Yy]$ ]]; then
    echo ""
    echo "🗑️  Starting cleanup..."
    
    # Safari Cache
    if [ -d ~/Library/Caches/com.apple.Safari ]; then
        echo "Removing Safari cache..."
        rm -rf ~/Library/Caches/com.apple.Safari
        echo "✅ Safari cache removed"
    else
        echo "ℹ️  Safari cache not found"
    fi
    
    # Google/Chrome Cache
    if [ -d ~/Library/Caches/Google ]; then
        echo "Removing Google/Chrome cache..."
        rm -rf ~/Library/Caches/Google
        echo "✅ Google/Chrome cache removed"
    else
        echo "ℹ️  Google cache not found"
    fi
    
    # Downloads Folder
    if [ -d ~/Downloads ]; then
        echo "Removing Downloads folder contents..."
        rm -rf ~/Downloads/*
        rm -rf ~/Downloads/.*  2>/dev/null  # Remove hidden files, ignore errors
        echo "✅ Downloads folder cleared"
    else
        echo "ℹ️  Downloads folder not found"
    fi
    
    echo ""
    echo "🎉 Cleanup completed successfully!"
    echo "💾 Disk space freed: ~11G"
    
else
    echo "❌ Cleanup cancelled."
fi
