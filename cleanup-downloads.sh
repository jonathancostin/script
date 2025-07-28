#!/bin/zsh

# Downloads Cleanup Script
# Finds and optionally deletes files older than 30 days in ~/Downloads

set -euo pipefail

DOWNLOADS_DIR="$HOME/Downloads"
DAYS_OLD=30
DRY_RUN=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --days)
            DAYS_OLD="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 [--dry-run] [--days N]"
            echo ""
            echo "Options:"
            echo "  --dry-run    List files that would be deleted without actually deleting them"
            echo "  --days N     Set number of days (default: 30)"
            echo "  --help       Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Check if Downloads directory exists
if [[ ! -d "$DOWNLOADS_DIR" ]]; then
    echo "Error: Downloads directory '$DOWNLOADS_DIR' not found"
    exit 1
fi

echo "🔍 Scanning Downloads folder for files older than $DAYS_OLD days..."
echo "Directory: $DOWNLOADS_DIR"
echo ""

# Find files older than specified days
OLD_FILES=$(find "$DOWNLOADS_DIR" -type f -mtime +$DAYS_OLD 2>/dev/null || true)
FILE_COUNT=$(echo "$OLD_FILES" | grep -c . || echo "0")

if [[ $FILE_COUNT -eq 0 ]]; then
    echo "✅ No files older than $DAYS_OLD days found in Downloads folder"
    exit 0
fi

# Calculate total size
TOTAL_SIZE=$(find "$DOWNLOADS_DIR" -type f -mtime +$DAYS_OLD -exec ls -ln {} \; 2>/dev/null | awk '{sum += $5} END {print sum+0}')
TOTAL_SIZE_HR=$(numfmt --to=iec-i --suffix=B $TOTAL_SIZE 2>/dev/null || echo "${TOTAL_SIZE} bytes")

echo "📊 Summary:"
echo "   Files found: $FILE_COUNT"
echo "   Total size: $TOTAL_SIZE_HR"
echo ""

if [[ "$DRY_RUN" == "true" ]]; then
    echo "🏷️  DRY RUN MODE - Files that would be deleted:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # List files with details
    find "$DOWNLOADS_DIR" -type f -mtime +$DAYS_OLD -exec ls -lah {} \; 2>/dev/null | while read -r line; do
        echo "  $line"
    done
    
    echo ""
    echo "💡 To actually delete these files, run without --dry-run flag"
    exit 0
fi

# Interactive confirmation
echo "📋 Files to be deleted:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Show first 10 files as preview
find "$DOWNLOADS_DIR" -type f -mtime +$DAYS_OLD -print0 | head -z -n 10 | while IFS= read -r -d '' file; do
    file_size=$(ls -lah "$file" 2>/dev/null | awk '{print $5}' || echo "unknown")
    file_date=$(ls -lah "$file" 2>/dev/null | awk '{print $6, $7, $8}' || echo "unknown")
    echo "  📄 $(basename "$file") ($file_size, modified: $file_date)"
done

if [[ $FILE_COUNT -gt 10 ]]; then
    echo "  ... and $((FILE_COUNT - 10)) more files"
fi

echo ""
echo "⚠️  WARNING: This action cannot be undone!"
echo ""

# Prompt for confirmation
while true; do
    echo -n "Do you want to delete these $FILE_COUNT files? [y/N/list]: "
    read -r response
    
    case $response in
        [Yy]|[Yy][Ee][Ss])
            echo ""
            echo "🗑️  Deleting files..."
            
            deleted_count=0
            find "$DOWNLOADS_DIR" -type f -mtime +$DAYS_OLD -print0 | while IFS= read -r -d '' file; do
                if rm -f "$file" 2>/dev/null; then
                    echo "  ✅ Deleted: $(basename "$file")"
                    ((deleted_count++))
                else
                    echo "  ❌ Failed to delete: $(basename "$file")"
                fi
            done
            
            echo ""
            echo "✨ Cleanup completed!"
            echo "   Freed up approximately: $TOTAL_SIZE_HR"
            break
            ;;
        [Ll]|[Ll][Ii][Ss][Tt])
            echo ""
            echo "📋 Complete list of files to be deleted:"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            find "$DOWNLOADS_DIR" -type f -mtime +$DAYS_OLD -exec ls -lah {} \; 2>/dev/null | while read -r line; do
                echo "  $line"
            done
            echo ""
            ;;
        [Nn]|[Nn][Oo]|"")
            echo ""
            echo "🚫 Operation cancelled. No files were deleted."
            exit 0
            ;;
        *)
            echo "Please answer 'y' for yes, 'n' for no, or 'list' to see all files."
            ;;
    esac
done
