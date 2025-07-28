#!/bin/zsh

# Xcode Derived Data Cleaner
# This script cleans Xcode derived data with safety checks and dry-run option

set -e  # Exit on any error

# Capture script name for help display
SCRIPT_NAME=$(basename "$0")

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to show usage
show_usage() {
    echo "Usage: $SCRIPT_NAME [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -d, --dry-run    Show what would be deleted without actually deleting"
    echo "  -f, --force      Skip confirmation prompt"
    echo "  -h, --help       Show this help message"
    echo ""
    echo "Examples:"
    echo "  $SCRIPT_NAME                # Interactive mode (prompts before deletion)"
    echo "  $SCRIPT_NAME --dry-run      # Show what would be deleted"
    echo "  $SCRIPT_NAME --force        # Delete without prompting"
    echo "  $SCRIPT_NAME -d             # Same as --dry-run"
}

# Parse command line arguments
DRY_RUN=false
FORCE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -f|--force)
            FORCE=true
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Check if Xcode is installed
print_info "Checking Xcode installation..."
if ! xcode-select -p &> /dev/null; then
    print_error "Xcode is not installed or command line tools are not configured."
    print_error "Run 'xcode-select --install' to install command line tools."
    exit 1
fi

XCODE_PATH=$(xcode-select -p)
print_success "Xcode found at: $XCODE_PATH"

# Define DerivedData path
DERIVED_DATA_PATH="$HOME/Library/Developer/Xcode/DerivedData"

print_info "Checking DerivedData directory..."

# Check if DerivedData directory exists
if [[ ! -d "$DERIVED_DATA_PATH" ]]; then
    print_warning "DerivedData directory does not exist at: $DERIVED_DATA_PATH"
    print_info "Nothing to clean."
    exit 0
fi

# Get directory size and contents info
if command -v du &> /dev/null; then
    TOTAL_SIZE=$(du -sh "$DERIVED_DATA_PATH" 2>/dev/null | cut -f1 || echo "Unknown")
else
    TOTAL_SIZE="Unknown"
fi

ITEM_COUNT=$(find "$DERIVED_DATA_PATH" -mindepth 1 -maxdepth 1 | wc -l | tr -d ' ')

print_info "DerivedData directory found at: $DERIVED_DATA_PATH"
print_info "Total size: $TOTAL_SIZE"
print_info "Contains $ITEM_COUNT items"

# Show contents if requested or in dry-run mode
if [[ "$DRY_RUN" == true ]] || [[ "$FORCE" == false ]]; then
    echo ""
    print_info "Contents of DerivedData directory:"
    if [[ $ITEM_COUNT -eq 0 ]]; then
        print_info "Directory is empty."
    else
        ls -la "$DERIVED_DATA_PATH" 2>/dev/null | tail -n +2 | while read -r line; do
            echo "  $line"
        done
    fi
    echo ""
fi

# Dry run mode
if [[ "$DRY_RUN" == true ]]; then
    print_warning "DRY RUN MODE - No files will be deleted"
    if [[ $ITEM_COUNT -gt 0 ]]; then
        print_info "Would delete all contents of: $DERIVED_DATA_PATH"
        print_info "This would free up approximately: $TOTAL_SIZE"
    else
        print_info "Directory is already empty - nothing would be deleted"
    fi
    exit 0
fi

# Check if directory is empty
if [[ $ITEM_COUNT -eq 0 ]]; then
    print_success "DerivedData directory is already empty."
    exit 0
fi

# Prompt for confirmation unless force flag is used
if [[ "$FORCE" == false ]]; then
    echo ""
    print_warning "This will permanently delete all contents of the DerivedData directory."
    print_warning "Size to be freed: $TOTAL_SIZE"
    echo ""
    read "response?Are you sure you want to proceed? (y/N): "
    
    case "$response" in
        [yY]|[yY][eE][sS])
            print_info "Proceeding with deletion..."
            ;;
        *)
            print_info "Operation cancelled by user."
            exit 0
            ;;
    esac
fi

# Perform the deletion
print_info "Cleaning DerivedData directory..."

# Temporarily disable strict error handling for deletion
set +e

# Disable glob warnings
setopt NULL_GLOB 2>/dev/null || true

# Use a more robust deletion method
# First delete visible files
rm -rf "$DERIVED_DATA_PATH"/* 2>/dev/null
# Then delete hidden files if they exist
rm -rf "$DERIVED_DATA_PATH"/.[!.]* "$DERIVED_DATA_PATH"/..?* 2>/dev/null

# Re-enable strict error handling
set -e

# Check if deletion was successful
REMAINING_COUNT_AFTER=$(find "$DERIVED_DATA_PATH" -mindepth 1 -maxdepth 1 | wc -l | tr -d ' ')
if [[ $REMAINING_COUNT_AFTER -lt $ITEM_COUNT ]]; then
    print_success "DerivedData directory has been cleaned successfully!"
    
    # Verify cleanup
    REMAINING_COUNT=$(find "$DERIVED_DATA_PATH" -mindepth 1 -maxdepth 1 | wc -l | tr -d ' ')
    if [[ $REMAINING_COUNT -eq 0 ]]; then
        print_success "Verification: Directory is now empty."
        print_info "Space freed: $TOTAL_SIZE"
    else
        print_warning "Verification: $REMAINING_COUNT items remain (may be system files)"
    fi
else
    print_error "Failed to clean DerivedData directory. Check permissions."
    exit 1
fi

print_info "Xcode DerivedData cleanup completed!"
