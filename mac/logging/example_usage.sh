#!/usr/bin/env bash

################################################################################
# Script Name:    example_usage.sh
# Description:    Demonstration of the logging and error handling framework
# Version:        1.0.0
################################################################################

# Source the logging framework
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$script_dir/logging_framework.sh"

# Initialize logging (optional: specify log file and level)
# You can also set LOG_LEVEL environment variable before running the script
setup_logging "" "${LOG_LEVEL:-INFO}"

# Validate required commands
validate_requirements "ls" "date" "whoami"

# Example of different log levels
log_info "Starting example script execution"
log_debug "This debug message will only show if LOG_LEVEL=DEBUG"

# Example of creating and tracking temporary files
temp_file=$(mktemp)
add_temp_file "$temp_file"
log_info "Created temporary file: $temp_file"

# Example of normal operation
log_info "Performing some operations..."
echo "Hello World" > "$temp_file"
log_success "Successfully wrote to temporary file"

# Example of warning
log_warn "This is a warning message - something might need attention"

# Example of error handling without exiting
if ! ls /nonexistent/path 2>/dev/null; then
    log_error "Failed to list non-existent directory (this is expected)"
fi

# Example showing how exit_on_error would work (commented out to avoid actually exiting)
# exit_on_error "This would cause the script to exit with cleanup"

# The script will automatically clean up temporary files when it exits
# due to the EXIT trap set in the logging framework

log_success "Example script completed successfully"
