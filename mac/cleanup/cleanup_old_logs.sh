#!/bin/zsh

# Script to clean up old log files in ~/Library/Logs
# Usage: ./cleanup_old_logs.sh [days]
# Environment variable: LOG_CLEANUP_DAYS (overrides default and command line argument)

# Set default age in days
DEFAULT_DAYS=7

# Function to display usage
usage() {
    echo "Usage: $0 [days]"
    echo "  days: Number of days old files should be to get deleted (default: $DEFAULT_DAYS)"
    echo ""
    echo "Environment Variables:"
    echo "  LOG_CLEANUP_DAYS: Override the default age in days"
    echo ""
    echo "Examples:"
    echo "  $0              # Delete files older than $DEFAULT_DAYS days"
    echo "  $0 14           # Delete files older than 14 days"
    echo "  LOG_CLEANUP_DAYS=3 $0  # Delete files older than 3 days (env var override)"
    exit 1
}

# Determine the age threshold
if [[ -n "$LOG_CLEANUP_DAYS" ]]; then
    # Environment variable takes precedence
    DAYS="$LOG_CLEANUP_DAYS"
    echo "Using environment variable LOG_CLEANUP_DAYS: $DAYS days"
elif [[ $# -eq 1 ]]; then
    # Command line argument
    DAYS="$1"
    # Validate that argument is a positive integer
    if ! [[ "$DAYS" =~ ^[0-9]+$ ]] || [[ "$DAYS" -le 0 ]]; then
        echo "Error: Days must be a positive integer"
        usage
    fi
    echo "Using command line argument: $DAYS days"
elif [[ $# -eq 0 ]]; then
    # Use default
    DAYS="$DEFAULT_DAYS"
    echo "Using default: $DAYS days"
else
    echo "Error: Too many arguments"
    usage
fi

# Define the logs directory
LOGS_DIR="$HOME/Library/Logs"

# Check if logs directory exists
if [[ ! -d "$LOGS_DIR" ]]; then
    echo "Error: Logs directory '$LOGS_DIR' does not exist"
    exit 1
fi

echo "Searching for log files older than $DAYS days in: $LOGS_DIR"

# Find and count files that would be deleted (dry run first)
echo "Files that will be deleted:"
OLD_FILES=$(find "$LOGS_DIR" -type f \( -name "*.log" -o -name "*.log.*" -o -name "*.out" -o -name "*.err" \) -mtime +$DAYS 2>/dev/null)

if [[ -z "$OLD_FILES" ]]; then
    echo "No log files found older than $DAYS days."
    exit 0
fi

# Display files to be deleted
echo "$OLD_FILES"
FILE_COUNT=$(echo "$OLD_FILES" | wc -l | tr -d ' ')
echo ""
echo "Found $FILE_COUNT log files older than $DAYS days."

# Ask for confirmation
echo -n "Do you want to delete these files? (y/N): "
read -r CONFIRM

case "$CONFIRM" in
    [yY]|[yY][eE][sS])
        echo "Deleting files..."
        DELETED_COUNT=0
        while IFS= read -r file; do
            if [[ -f "$file" ]]; then
                if rm "$file" 2>/dev/null; then
                    echo "Deleted: $file"
                    ((DELETED_COUNT++))
                else
                    echo "Failed to delete: $file"
                fi
            fi
        done <<< "$OLD_FILES"
        
        echo ""
        echo "Successfully deleted $DELETED_COUNT out of $FILE_COUNT files."
        ;;
    *)
        echo "Operation cancelled."
        exit 0
        ;;
esac
