# Shell Script Logging and Error Handling Framework

A comprehensive logging and error handling framework for shell scripts that provides structured logging, automatic cleanup, and robust error handling.

## Overview

This framework provides:
- **Structured logging** with multiple log levels (INFO, WARN, ERROR, SUCCESS, DEBUG)
- **Automatic error handling** with `set -euo pipefail` 
- **Signal trapping** for graceful cleanup on script termination
- **Temporary file management** with automatic cleanup
- **Colored terminal output** for better readability
- **File logging** support with timestamps
- **Error reporting** with line numbers and failed commands

## Quick Start

1. **Source the framework** in your script:
```bash
#!/usr/bin/env bash

# Source the logging framework
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$script_dir/logging_framework.sh"

# Initialize logging (optional)
setup_logging "" "INFO"
```

2. **Use logging functions**:
```bash
log_info "Starting process..."
log_warn "This is a warning"
log_error "Something went wrong"
log_success "Operation completed successfully"
```

3. **Handle errors gracefully**:
```bash
# This will log the error and exit with cleanup
exit_on_error "Critical error occurred" 1
```

## Core Functions

### Logging Functions

#### `log_info "message"`
Logs informational messages in blue color.
```bash
log_info "Processing user data..."
```

#### `log_warn "message"`
Logs warning messages in yellow color.
```bash
log_warn "Configuration file not found, using defaults"
```

#### `log_error "message"`
Logs error messages in red color.
```bash
log_error "Failed to connect to database"
```

#### `log_success "message"`
Logs success messages in green color.
```bash
log_success "All files processed successfully"
```

#### `log_debug "message"`
Logs debug messages in gray color (only shown when LOG_LEVEL=DEBUG).
```bash
log_debug "Variable value: $my_variable"
```

### Error Handling

#### `exit_on_error "message" [exit_code]`
Logs an error message and exits the script with optional exit code (defaults to 1).
Automatically triggers cleanup before exiting.
```bash
if ! command -v required_tool >/dev/null; then
    exit_on_error "Required tool 'required_tool' not found" 127
fi
```

#### `validate_requirements "cmd1" "cmd2" ...`
Validates that required commands are available. Exits with error if any are missing.
```bash
validate_requirements "curl" "jq" "git"
```

### Temporary File Management

#### `add_temp_file "filepath"`
Registers a temporary file for automatic cleanup on script exit.
```bash
temp_file=$(mktemp)
add_temp_file "$temp_file"
```

#### `cleanup_temp_files`
Manually triggers cleanup of all registered temporary files.
```bash
cleanup_temp_files  # Usually called automatically
```

### Configuration

#### `setup_logging [log_file] [log_level]`
Initializes logging with optional file output and log level.
```bash
# Console only with INFO level
setup_logging "" "INFO"

# Log to file with DEBUG level
setup_logging "/tmp/myapp.log" "DEBUG"

# Use environment variables
setup_logging "${LOG_FILE}" "${LOG_LEVEL:-INFO}"
```

## Configuration Options

### Environment Variables

#### `LOG_LEVEL`
Controls which log messages are displayed:
- `DEBUG`: Shows all messages including debug
- `INFO`: Shows info, warn, error, success (default)
- `WARN`: Shows warn, error, success only
- `ERROR`: Shows error and success only

```bash
# Run with debug logging
LOG_LEVEL=DEBUG ./your_script.sh

# Run with minimal logging
LOG_LEVEL=ERROR ./your_script.sh
```

#### `LOG_FILE`
Specifies the file to write logs to (in addition to console output):
```bash
LOG_FILE="/var/log/myapp.log" ./your_script.sh
```

### Built-in Error Handling

The framework automatically sets:
- `set -euo pipefail` for strict error handling
- Signal traps for EXIT, INT, TERM, HUP, and ERR
- Automatic cleanup on script termination

## Signal Handling

The framework automatically handles these signals:
- **EXIT**: Normal script termination - performs cleanup
- **INT** (Ctrl+C): User interruption - logs warning and cleans up
- **TERM**: Termination signal - logs warning and cleans up  
- **HUP**: Hangup signal - logs warning and cleans up
- **ERR**: Command failure - logs error with line number and cleans up

## Examples

### Basic Usage
```bash
#!/usr/bin/env bash

source "logging_framework.sh"
setup_logging "" "INFO"

log_info "Starting backup process..."

# Validate required tools
validate_requirements "rsync" "tar"

# Create temporary directory
temp_dir=$(mktemp -d)
add_temp_file "$temp_dir"

# Perform backup
if rsync -av /source/ "$temp_dir/"; then
    log_success "Files synchronized successfully"
else
    exit_on_error "Failed to synchronize files"
fi

log_info "Backup completed"
```

### Advanced Usage with File Logging
```bash
#!/usr/bin/env bash

source "logging_framework.sh"

# Setup logging to file with debug level
setup_logging "/var/log/deploy.log" "DEBUG"

log_info "Starting deployment process"
log_debug "Current working directory: $(pwd)"

# Example of error handling without exiting
if ! git pull origin main 2>/dev/null; then
    log_warn "Failed to pull latest changes, continuing with current code"
fi

# Critical error that should stop execution
if ! ./build.sh; then
    exit_on_error "Build failed, cannot continue deployment" 2
fi

log_success "Deployment completed successfully"
```

### Error Handling Example
```bash
#!/usr/bin/env bash

source "logging_framework.sh"
setup_logging "" "INFO"

# This will automatically trigger error handling if the command fails
log_info "Checking disk space..."
df -h /

# Handle non-critical errors manually
if ! ping -c 1 google.com >/dev/null 2>&1; then
    log_warn "Internet connectivity check failed"
else
    log_success "Internet connectivity verified"
fi

# Critical error - will exit with cleanup
if [[ ! -f "/important/config/file" ]]; then
    exit_on_error "Critical configuration file missing"
fi
```

## Log Format

All log messages follow this format:
```
[YYYY-MM-DD HH:MM:SS] [script_name] [LEVEL] message
```

Example output:
```
[2025-07-28 11:48:08] [backup.sh] [INFO] Starting backup process...
[2025-07-28 11:48:08] [backup.sh] [WARN] Configuration file not found, using defaults
[2025-07-28 11:48:09] [backup.sh] [SUCCESS] Backup completed successfully
```

## Best Practices

1. **Always source the framework first** before any other operations
2. **Use appropriate log levels** - reserve ERROR for actual problems
3. **Register temporary files** immediately after creation
4. **Use exit_on_error** for critical failures that should stop execution
5. **Validate requirements early** in your script
6. **Use DEBUG level** for troubleshooting and development
7. **Set LOG_FILE** for production scripts that need audit trails

## Integration with Existing Scripts

To add the framework to an existing script:

1. Add the source line at the top
2. Replace `echo` statements with appropriate `log_*` functions  
3. Add `exit_on_error` calls for critical failures
4. Register any temporary files with `add_temp_file`
5. Add requirement validation with `validate_requirements`

## Troubleshooting

- **Colors not showing**: Check if your terminal supports ANSI colors
- **Debug messages not appearing**: Ensure LOG_LEVEL is set to DEBUG
- **Permission errors on log file**: Check write permissions for LOG_FILE directory
- **Script exits unexpectedly**: Check for unhandled errors due to `set -euo pipefail`

## Files

- `logging_framework.sh` - Main framework file
- `example_usage.sh` - Complete example demonstrating all features
- `LOGGING_FRAMEWORK_README.md` - This documentation

## License

MIT License - Use freely in your projects.
