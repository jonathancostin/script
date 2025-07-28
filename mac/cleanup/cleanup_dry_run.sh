#!/bin/zsh

echo "=== DRY RUN - Items that would be deleted ==="
echo ""

echo "📁 Safari Cache (~4.0K):"
if [ -d ~/Library/Caches/com.apple.Safari ]; then
    find ~/Library/Caches/com.apple.Safari -type f 2>/dev/null | head -5
    echo "... and $(find ~/Library/Caches/com.apple.Safari -type f 2>/dev/null | wc -l | tr -d ' ') total files"
else
    echo "  No Safari cache found"
fi
echo ""

echo "📁 Google/Chrome Cache (~3.1M):"
if [ -d ~/Library/Caches/Google ]; then
    find ~/Library/Caches/Google -type f 2>/dev/null | head -5
    echo "... and $(find ~/Library/Caches/Google -type f 2>/dev/null | wc -l | tr -d ' ') total files"
else
    echo "  No Google cache found"
fi
echo ""

echo "📁 Downloads Folder (~11G, 31 items):"
if [ -d ~/Downloads ]; then
    ls -la ~/Downloads | head -10
    echo "... showing first 10 items"
else
    echo "  No Downloads folder found"
fi
echo ""

echo "🚨 TOTAL DATA TO BE DELETED: ~11G + 3.1M + 4.0K"
echo "This is a DRY RUN - nothing was actually deleted."
