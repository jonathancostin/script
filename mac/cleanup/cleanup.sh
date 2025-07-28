#!/usr/bin/env bash

################################################################################
# Script Name:    cleanup.sh
# Description:    Mac System Cleanup Script - Comprehensive cleanup utility
#                 for macOS systems to remove temporary files, caches, downloads,
#                 and empty trash to optimize system performance
# Author:         [Your Name]
# Email:          [your.email@domain.com]
# Date Created:   [Creation Date]
# Last Modified:  [Modification Date]
# Version:        1.0.0
# License:        MIT License
#
# Usage:
#   ./cleanup.sh [OPTIONS]
#
# Features:
#   - Cleans user caches from ~/Library/Caches with critical cache backup
#   - Empties Downloads folder (~/Downloads)
#   - Empties Trash (~/.Trash) permanently
#   - Dry-run mode to preview actions
#   - Verbose logging and confirmation prompts
#   - Individual confirmation for each cleanup operation
#
# Examples:
#   ./cleanup.sh                    # Run full cleanup with confirmations
#   ./cleanup.sh --dry-run          # Preview what would be cleaned
#   ./cleanup.sh --yes              # Run cleanup without confirmations
#   ./cleanup.sh --help             # Show help information
#   ./cleanup.sh --verbose          # Run with verbose output
#   ./cleanup.sh --quick            # Quick cleanup (basic items only)
#
# Supported Options:
#   -h, --help      Display this help message and exit
#   -n, --dry-run   Show what would be cleaned without actually cleaning
#   -y, --yes       Skip confirmation prompts and proceed automatically
#   -v, --verbose   Enable verbose output during cleanup
#   -q, --quick     Perform quick cleanup (basic items only)
#   --version       Display script version information
#
# Requirements:
#   - macOS 10.12 or later
#   - Administrator privileges may be required for some operations
#   - Sufficient disk space for temporary operations
#
# Disclaimer:
#   This script is provided "as is" without warranty of any kind.
#   Use at your own risk. Always backup important data before running
#   system cleanup operations. The author is not responsible for any
#   data loss or system damage that may occur from using this script.
#
# License:
#   MIT License - See LICENSE file for details
#   Copyright (c) [Year] [Your Name]
#
################################################################################

# Script version
VERSION="1.0.0"

# Global variables for command-line options
DRY_RUN=false
SKIP_CONFIRMATIONS=false
VERBOSE=false
QUICK_MODE=false

# Usage function
usage() {
  cat <<EOF
Usage: $0 [OPTIONS]

Mac System Cleanup Script - Comprehensive cleanup utility for macOS systems
to remove temporary files, caches, and optimize system performance.

OPTIONS:
    -n, --dry-run       Show what would be cleaned without actually cleaning
    -y, --yes           Skip confirmation prompts and proceed automatically
    -h, --help          Display this help message and exit
    -v, --verbose       Enable verbose output during cleanup
    -q, --quick         Perform quick cleanup (basic items only)
    --version           Display script version information

EXAMPLES:
    $0                  Run full cleanup with confirmations
    $0 --dry-run        Preview what would be cleaned
    $0 --yes            Run cleanup without confirmations
    $0 -n -v            Dry run with verbose output
    $0 --quick --yes    Quick cleanup without confirmations

REQUIREMENTS:
    - macOS 10.12 or later
    - Administrator privileges may be required for some operations
    - Sufficient disk space for temporary operations

DISCLAIMER:
    This script is provided "as is" without warranty of any kind.
    Use at your own risk. Always backup important data before running
    system cleanup operations.

LICENSE:
    MIT License - Copyright (c) $(date +%Y)
EOF
}

# Function to display version information
show_version() {
  echo "Mac Cleanup Script v$VERSION"
  echo "Copyright (c) $(date +%Y)"
  echo "Licensed under MIT License"
}

# Function to log messages based on verbosity
log() {
  if [[ "$VERBOSE" == true ]]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
  fi
}

# Function to confirm actions (unless --yes is specified)
confirm() {
  if [[ "$SKIP_CONFIRMATIONS" == true ]]; then
    return 0
  fi

  read -p "$1 (y/N): " -n 1 -r
  echo
  [[ $REPLY =~ ^[Yy]$ ]]
}

# Parse command-line arguments
parse_arguments() {
  while [[ $# -gt 0 ]]; do
    case $1 in
    -n | --dry-run)
      DRY_RUN=true
      log "Dry run mode enabled"
      shift
      ;;
    -y | --yes)
      SKIP_CONFIRMATIONS=true
      log "Skipping confirmations"
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    -v | --verbose)
      VERBOSE=true
      log "Verbose mode enabled"
      shift
      ;;
    -q | --quick)
      QUICK_MODE=true
      log "Quick mode enabled"
      shift
      ;;
    --version)
      show_version
      exit 0
      ;;
    -*)
      echo "Error: Unknown option $1" >&2
      echo "Use '$0 --help' for usage information." >&2
      exit 1
      ;;
    *)
      echo "Error: Unexpected argument $1" >&2
      echo "Use '$0 --help' for usage information." >&2
      exit 1
      ;;
    esac
  done
}

# Parse command-line arguments
parse_arguments "$@"

# Display current configuration if verbose
if [[ "$VERBOSE" == true ]]; then
  echo "Configuration:"
  echo "  Dry Run: $DRY_RUN"
  echo "  Skip Confirmations: $SKIP_CONFIRMATIONS"
  echo "  Verbose: $VERBOSE"
  echo "  Quick Mode: $QUICK_MODE"
  echo
fi

echo "Starting Mac cleanup process..."

# Function to backup critical caches if needed
backup_critical_caches() {
  local backup_dir="$HOME/.cleanup_backup/caches_$(date +%Y%m%d_%H%M%S)"
  local critical_caches=(
    "com.apple.Safari"
    "com.apple.mail"
    "com.apple.Photos"
    "com.apple.iPhoto"
  )

  log "Checking for critical caches to backup..."

  for cache in "${critical_caches[@]}"; do
    local cache_path="$HOME/Library/Caches/$cache"
    if [[ -d "$cache_path" ]]; then
      if [[ "$DRY_RUN" == true ]]; then
        echo "[DRY RUN] Would backup critical cache: $cache_path"
      else
        log "Backing up critical cache: $cache"
        mkdir -p "$backup_dir"
        cp -R "$cache_path" "$backup_dir/" 2>/dev/null || {
          echo "Warning: Failed to backup $cache" >&2
        }
      fi
    fi
  done

  if [[ -d "$backup_dir" && "$DRY_RUN" == false ]]; then
    echo "Critical caches backed up to: $backup_dir"
  fi
}

# Function to empty Trash
cleanup_trash() {
  local trash_dir="$HOME/.Trash"
  local total_size=0
  local file_count=0

  log "Starting Trash cleanup for: $trash_dir"

  # Check if Trash directory exists
  if [[ ! -d "$trash_dir" ]]; then
    echo "Trash directory not found: $trash_dir"
    return 0
  fi

  # Calculate current Trash size and file count
  if command -v du >/dev/null 2>&1; then
    total_size=$(du -sh "$trash_dir" 2>/dev/null | cut -f1 || echo "unknown")
    file_count=$(find "$trash_dir" -type f 2>/dev/null | wc -l | tr -d ' ')
  fi

  echo "Current Trash size: $total_size"
  echo "Total files in Trash: $file_count"

  # Show contents if there are files
  if [[ $file_count -gt 0 ]]; then
    echo "\nTrash contents:"
    ls -lah "$trash_dir" 2>/dev/null | head -10
    if [[ $file_count -gt 10 ]]; then
      echo "  ... and $(($file_count - 10)) more items"
    fi
    echo ""
  else
    echo "Trash is already empty."
    return 0
  fi

  # Prompt user unless confirmations are skipped
  if [[ "$SKIP_CONFIRMATIONS" == false && "$DRY_RUN" == false ]]; then
    echo "⚠️  WARNING: This will permanently delete all files in Trash!"
    echo "⚠️  These files cannot be easily recovered once deleted."
    if ! confirm "Empty Trash and permanently delete $file_count files ($total_size)?"; then
      echo "Trash cleanup cancelled by user."
      return 0
    fi
  fi

  if [[ "$DRY_RUN" == true ]]; then
    echo "[DRY RUN] Would permanently delete contents of: $trash_dir"
    echo "[DRY RUN] Would delete $file_count files ($total_size)"

    # Show what would be deleted
    echo "[DRY RUN] Items that would be permanently removed:"
    find "$trash_dir" -maxdepth 1 -mindepth 1 2>/dev/null | head -10 | while read -r item; do
      echo "[DRY RUN]   - $(basename "$item")"
    done

    if [[ $file_count -gt 10 ]]; then
      echo "[DRY RUN]   ... and $(($file_count - 10)) more items"
    fi
  else
    echo "Emptying Trash..."
    local deleted_count=0
    local failed_count=0

    # Remove all contents of Trash
    find "$trash_dir" -maxdepth 1 -mindepth 1 2>/dev/null | while read -r item; do
      local item_name=$(basename "$item")
      log "Deleting: $item_name"

      if rm -rf "$item" 2>/dev/null; then
        echo "  ✓ Deleted: $item_name"
        ((deleted_count++))
      else
        echo "  ✗ Failed to delete: $item_name" >&2
        ((failed_count++))
      fi
    done

    # Calculate final size
    local new_size="0B"
    local remaining_files=0
    if command -v du >/dev/null 2>&1; then
      new_size=$(du -sh "$trash_dir" 2>/dev/null | cut -f1 || echo "0B")
      remaining_files=$(find "$trash_dir" -type f 2>/dev/null | wc -l | tr -d ' ')
    fi

    echo "Trash cleanup completed."
    echo "  Files deleted: $file_count"
    echo "  Space freed: $total_size"
    echo "  Remaining files: $remaining_files"
    log "Trash cleanup statistics: deleted $file_count files, freed $total_size"
  fi
}

# Function to cleanup user caches in ~/Library/Caches
cleanup_user_caches() {
  local cache_dir="$HOME/Library/Caches"
  local total_size=0
  local file_count=0

  log "Starting user cache cleanup for: $cache_dir"

  # Check if cache directory exists
  if [[ ! -d "$cache_dir" ]]; then
    echo "Cache directory not found: $cache_dir"
    return 0
  fi

  # Calculate current cache size and file count
  if command -v du >/dev/null 2>&1; then
    total_size=$(du -sh "$cache_dir" 2>/dev/null | cut -f1 || echo "unknown")
    file_count=$(find "$cache_dir" -type f 2>/dev/null | wc -l | tr -d ' ')
  fi

  echo "Current cache directory size: $total_size"
  echo "Total files in cache directory: $file_count"

  # Prompt user unless confirmations are skipped
  if [[ "$SKIP_CONFIRMATIONS" == false && "$DRY_RUN" == false ]]; then
    if ! confirm "Clean user caches in $cache_dir? This will remove $file_count files ($total_size)"; then
      echo "User cache cleanup cancelled by user."
      return 0
    fi
  fi

  # Backup critical caches first
  backup_critical_caches

  if [[ "$DRY_RUN" == true ]]; then
    echo "[DRY RUN] Would remove contents of: $cache_dir"
    echo "[DRY RUN] Would delete $file_count files ($total_size)"

    # Show what would be deleted (first 20 items)
    echo "[DRY RUN] Sample items that would be removed:"
    find "$cache_dir" -maxdepth 2 -type d 2>/dev/null | head -20 | while read -r item; do
      echo "[DRY RUN]   - $item"
    done

    if [[ $file_count -gt 20 ]]; then
      echo "[DRY RUN]   ... and $(($file_count - 20)) more items"
    fi
  else
    echo "Cleaning user caches..."
    local cleaned_count=0
    local failed_count=0

    # Remove contents of each subdirectory in ~/Library/Caches
    find "$cache_dir" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | while read -r cache_subdir; do
      local subdir_name=$(basename "$cache_subdir")
      log "Cleaning cache subdirectory: $subdir_name"

      if rm -rf "${cache_subdir:?}/"* 2>/dev/null; then
        echo "  ✓ Cleaned: $subdir_name"
        ((cleaned_count++))
      else
        echo "  ✗ Failed to clean: $subdir_name" >&2
        ((failed_count++))
      fi
    done

    # Also remove any loose files in the root cache directory
    find "$cache_dir" -maxdepth 1 -type f 2>/dev/null | while read -r cache_file; do
      local file_name=$(basename "$cache_file")
      log "Removing cache file: $file_name"

      if rm -f "$cache_file" 2>/dev/null; then
        echo "  ✓ Removed file: $file_name"
      else
        echo "  ✗ Failed to remove file: $file_name" >&2
      fi
    done

    # Calculate space freed
    local new_size="unknown"
    if command -v du >/dev/null 2>&1; then
      new_size=$(du -sh "$cache_dir" 2>/dev/null | cut -f1 || echo "unknown")
    fi

    echo "User cache cleanup completed."
    echo "  Previous size: $total_size"
    echo "  Current size: $new_size"
    log "User cache cleanup statistics: $cleaned_count cleaned, $failed_count failed"
  fi
}

# Function to cleanup Downloads folder
cleanup_downloads() {
  local downloads_dir="$HOME/Downloads"
  local total_size=0
  local file_count=0

  log "Starting Downloads cleanup for: $downloads_dir"

  # Check if Downloads directory exists
  if [[ ! -d "$downloads_dir" ]]; then
    echo "Downloads directory not found: $downloads_dir"
    return 0
  fi

  # Calculate current Downloads size and file count
  if command -v du >/dev/null 2>&1; then
    total_size=$(du -sh "$downloads_dir" 2>/dev/null | cut -f1 || echo "unknown")
    file_count=$(find "$downloads_dir" -maxdepth 1 -mindepth 1 2>/dev/null | wc -l | tr -d ' ')
  fi

  echo "Current Downloads size: $total_size"
  echo "Total items in Downloads: $file_count"

  # Show contents if there are files
  if [[ $file_count -gt 0 ]]; then
    echo "\nDownloads contents:"
    ls -lah "$downloads_dir" 2>/dev/null | head -10
    if [[ $file_count -gt 10 ]]; then
      echo "  ... and $(($file_count - 10)) more items"
    fi
    echo ""
  else
    echo "Downloads folder is already empty."
    return 0
  fi

  # Prompt user unless confirmations are skipped
  if [[ "$SKIP_CONFIRMATIONS" == false && "$DRY_RUN" == false ]]; then
    echo "⚠️  WARNING: This will permanently delete all files in Downloads!"
    echo "⚠️  Make sure you've backed up any important downloads."
    if ! confirm "Clear Downloads folder and delete $file_count items ($total_size)?"; then
      echo "Downloads cleanup cancelled by user."
      return 0
    fi
  fi

  if [[ "$DRY_RUN" == true ]]; then
    echo "[DRY RUN] Would delete contents of: $downloads_dir"
    echo "[DRY RUN] Would delete $file_count items ($total_size)"

    # Show what would be deleted
    echo "[DRY RUN] Items that would be removed:"
    find "$downloads_dir" -maxdepth 1 -mindepth 1 2>/dev/null | head -10 | while read -r item; do
      echo "[DRY RUN]   - $(basename "$item")"
    done

    if [[ $file_count -gt 10 ]]; then
      echo "[DRY RUN]   ... and $(($file_count - 10)) more items"
    fi
  else
    echo "Clearing Downloads folder..."
    local deleted_count=0
    local failed_count=0

    # Remove all contents of Downloads
    find "$downloads_dir" -maxdepth 1 -mindepth 1 2>/dev/null | while read -r item; do
      local item_name=$(basename "$item")
      log "Deleting: $item_name"

      if rm -rf "$item" 2>/dev/null; then
        echo "  ✓ Deleted: $item_name"
        ((deleted_count++))
      else
        echo "  ✗ Failed to delete: $item_name" >&2
        ((failed_count++))
      fi
    done

    # Calculate final size
    local new_size="0B"
    local remaining_files=0
    if command -v du >/dev/null 2>&1; then
      new_size=$(du -sh "$downloads_dir" 2>/dev/null | cut -f1 || echo "0B")
      remaining_files=$(find "$downloads_dir" -maxdepth 1 -mindepth 1 2>/dev/null | wc -l | tr -d ' ')
    fi

    echo "Downloads cleanup completed."
    echo "  Items deleted: $file_count"
    echo "  Space freed: $total_size"
    echo "  Remaining items: $remaining_files"
    log "Downloads cleanup statistics: deleted $file_count items, freed $total_size"
  fi
}

# Main cleanup execution
if [[ "$DRY_RUN" == true ]]; then
  echo "[DRY RUN] Starting cleanup preview..."
  echo "\n=== USER CACHES ==="
  cleanup_user_caches
  echo "\n=== DOWNLOADS FOLDER ==="
  cleanup_downloads
  echo "\n=== TRASH ==="
  cleanup_trash
  echo "\n[DRY RUN] Cleanup preview completed."
else
  if [[ "$SKIP_CONFIRMATIONS" == false ]]; then
    if ! confirm "Proceed with cleanup? This will clean caches, Downloads, and Trash"; then
      echo "Cleanup cancelled by user."
      exit 0
    fi
  fi
  echo "Performing actual cleanup..."
  echo "\n=== CLEANING USER CACHES ==="
  cleanup_user_caches
  echo "\n=== CLEANING DOWNLOADS FOLDER ==="
  cleanup_downloads
  echo "\n=== EMPTYING TRASH ==="
  cleanup_trash
fi

log "Cleanup process completed."
echo "Cleanup process completed."
