#!/usr/bin/env bash

################################################################################
# Script Name:    logging_framework.sh
# Description:    Comprehensive logging and error handling framework for shell scripts
# Version:        1.0.0
# Usage:          source logging_framework.sh
################################################################################

# Set strict error handling
set -euo pipefail

# Global variables for logging
LOG_LEVEL="${LOG_LEVEL:-INFO}"
LOG_FILE="${LOG_FILE:-}"
TEMP_FILES=()
SCRIPT_NAME="${0##*/}"

# ANSI color codes for terminal output
COLOR_RED='\033[0;31m'
COLOR_YELLOW='\033[1;33m'
COLOR_BLUE='\033[0;34m'
COLOR_GREEN='\033[0;32m'
COLOR_GRAY='\033[0;37m'
COLOR_NC='\033[0m'  # No Color

################################################################################
# Function: get_timestamp
# Description: Get current timestamp in ISO 8601 format
# Returns: Formatted timestamp string
################################################################################
get_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

################################################################################
# Function: write_log
# Description: Core logging function that handles output to both console and file
# Arguments:
#   $1 - Log level (INFO, WARN, ERROR)
#   $2 - Log message
#   $3 - Color code (optional)
################################################################################
write_log() {
    local level="$1"
    local message="$2"
    local color="${3:-$COLOR_NC}"
    local timestamp
    timestamp=$(get_timestamp)
    
    local log_entry="[$timestamp] [$SCRIPT_NAME] [$level] $message"
    
    # Output to console with color
    if [[ -t 1 ]]; then  # Check if stdout is a terminal
        echo -e "${color}${log_entry}${COLOR_NC}" >&2
    else
        echo "$log_entry" >&2
    fi
    
    # Output to log file if specified
    if [[ -n "$LOG_FILE" ]]; then
        echo "$log_entry" >> "$LOG_FILE"
    fi
}

################################################################################
# Function: log_info
# Description: Log informational messages
# Arguments:
#   $1 - Log message
################################################################################
log_info() {
    local message="$1"
    write_log "INFO" "$message" "$COLOR_BLUE"
}

################################################################################
# Function: log_warn
# Description: Log warning messages
# Arguments:
#   $1 - Log message
################################################################################
log_warn() {
    local message="$1"
    write_log "WARN" "$message" "$COLOR_YELLOW"
}

################################################################################
# Function: log_error
# Description: Log error messages
# Arguments:
#   $1 - Log message
################################################################################
log_error() {
    local message="$1"
    write_log "ERROR" "$message" "$COLOR_RED"
}

################################################################################
# Function: log_success
# Description: Log success messages
# Arguments:
#   $1 - Log message
################################################################################
log_success() {
    local message="$1"
    write_log "SUCCESS" "$message" "$COLOR_GREEN"
}

################################################################################
# Function: log_debug
# Description: Log debug messages (only shown when LOG_LEVEL=DEBUG)
# Arguments:
#   $1 - Log message
################################################################################
log_debug() {
    if [[ "$LOG_LEVEL" == "DEBUG" ]]; then
        local message="$1"
        write_log "DEBUG" "$message" "$COLOR_GRAY"
    fi
}

################################################################################
# Function: exit_on_error
# Description: Log error message and exit with specified code
# Arguments:
#   $1 - Error message
#   $2 - Exit code (optional, defaults to 1)
################################################################################
exit_on_error() {
    local message="$1"
    local exit_code="${2:-1}"
    
    log_error "$message"
    log_error "Script execution failed. Exit code: $exit_code"
    
    # Trigger cleanup before exit
    cleanup_temp_files
    exit "$exit_code"
}

################################################################################
# Function: add_temp_file
# Description: Add a temporary file to the cleanup list
# Arguments:
#   $1 - Path to temporary file
################################################################################
add_temp_file() {
    local temp_file="$1"
    TEMP_FILES+=("$temp_file")
    log_debug "Added temporary file to cleanup list: $temp_file"
}

################################################################################
# Function: cleanup_temp_files
# Description: Clean up all temporary files registered with add_temp_file
################################################################################
cleanup_temp_files() {
    if [[ ${#TEMP_FILES[@]} -gt 0 ]]; then
        log_info "Cleaning up ${#TEMP_FILES[@]} temporary file(s)..."
        
        for temp_file in "${TEMP_FILES[@]}"; do
            if [[ -e "$temp_file" ]]; then
                rm -rf "$temp_file"
                log_debug "Removed temporary file: $temp_file"
            fi
        done
        
        TEMP_FILES=()
        log_info "Temporary files cleanup completed"
    fi
}

################################################################################
# Function: handle_exit
# Description: Signal handler for script termination
# Arguments:
#   $1 - Signal number (optional)
################################################################################
handle_exit() {
    local signal="${1:-}"
    
    if [[ -n "$signal" ]]; then
        log_warn "Received signal $signal - performing cleanup..."
    else
        log_debug "Script exiting normally - performing cleanup..."
    fi
    
    cleanup_temp_files
}

################################################################################
# Function: handle_error
# Description: Error handler for unexpected errors
# Arguments:
#   $1 - Line number where error occurred
#   $2 - Exit code
################################################################################
handle_error() {
    local line_number="$1"
    local exit_code="$2"
    
    log_error "An error occurred on line $line_number (exit code: $exit_code)"
    log_error "Command that failed: ${BASH_COMMAND}"
    
    cleanup_temp_files
    exit "$exit_code"
}

# Set up signal traps for cleanup
trap 'handle_exit' EXIT
trap 'handle_exit SIGINT' INT
trap 'handle_exit SIGTERM' TERM
trap 'handle_exit SIGHUP' HUP
trap 'handle_error ${LINENO} $?' ERR

################################################################################
# Function: setup_logging
# Description: Initialize logging with optional log file
# Arguments:
#   $1 - Log file path (optional)
#   $2 - Log level (optional, defaults to INFO)
################################################################################
setup_logging() {
    local log_file="${1:-}"
    local log_level="${2:-INFO}"
    
    LOG_FILE="$log_file"
    LOG_LEVEL="$log_level"
    
    if [[ -n "$LOG_FILE" ]]; then
        # Create log file directory if it doesn't exist
        local log_dir
        log_dir=$(dirname "$LOG_FILE")
        mkdir -p "$log_dir"
        
        log_info "Logging initialized - File: $LOG_FILE, Level: $LOG_LEVEL"
    else
        log_info "Logging initialized - Console only, Level: $LOG_LEVEL"
    fi
}

################################################################################
# Function: validate_requirements
# Description: Validate that required commands/tools are available
# Arguments:
#   $@ - List of required commands
################################################################################
validate_requirements() {
    local missing_commands=()
    
    for cmd in "$@"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_commands+=("$cmd")
        fi
    done
    
    if [[ ${#missing_commands[@]} -gt 0 ]]; then
        exit_on_error "Missing required commands: ${missing_commands[*]}"
    fi
    
    log_debug "All required commands are available: $*"
}

# Initialize basic logging on source
log_debug "Logging framework loaded successfully"
