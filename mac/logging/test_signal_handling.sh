#!/usr/bin/env bash

################################################################################
# Script Name:    test_signal_handling.sh
# Description:    Test script to demonstrate signal handling and cleanup
# Usage:          ./test_signal_handling.sh (then press Ctrl+C to test)
################################################################################

# Source the logging framework
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$script_dir/logging_framework.sh"

# Initialize logging
setup_logging "" "DEBUG"

log_info "Starting signal handling test..."
log_info "This script will create temporary files and then wait"
log_info "Press Ctrl+C to test the cleanup functionality"

# Create multiple temporary files to test cleanup
for i in {1..3}; do
    temp_file=$(mktemp)
    add_temp_file "$temp_file"
    echo "Test data $i" > "$temp_file"
    log_info "Created temporary file $i: $temp_file"
done

# Create a temporary directory
temp_dir=$(mktemp -d)
add_temp_file "$temp_dir"
log_info "Created temporary directory: $temp_dir"

# Add some files to the directory
echo "Important data" > "$temp_dir/data.txt"
echo "More data" > "$temp_dir/more_data.txt"

log_info "All temporary files created. Now waiting..."
log_info "Press Ctrl+C to test signal handling and cleanup"

# Wait indefinitely (or until interrupted)
while true; do
    sleep 1
    log_debug "Still running... (press Ctrl+C to test cleanup)"
done

log_success "Script completed normally (this shouldn't be reached)"
