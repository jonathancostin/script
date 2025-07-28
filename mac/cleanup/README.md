# Mac Cleanup Script

A comprehensive macOS system cleanup utility that safely removes temporary files, caches, downloads, and empties trash to optimize system performance and free up disk space.

## Overview

This script provides a safe and thorough approach to cleaning up common macOS system locations that accumulate temporary data over time. It includes safety features like dry-run mode, confirmation prompts, and critical cache backup to prevent data loss.

## Features

- 🧹 **User Cache Cleanup**: Removes cached data from `~/Library/Caches` with critical cache backup
- 📁 **Downloads Folder**: Empties the `~/Downloads` directory 
- 🗑️ **Trash Management**: Permanently empties the Trash (`~/.Trash`)
- 👀 **Dry-Run Mode**: Preview what would be cleaned without making changes
- 💬 **Confirmation Prompts**: Individual confirmation for each cleanup operation
- 🔧 **Verbose Logging**: Detailed output for troubleshooting and monitoring
- ⚡ **Quick Mode**: Basic cleanup operations only
- 🛡️ **Safety Features**: Critical cache backup and error handling

## Usage

### Basic Usage
```bash
# Run full cleanup with confirmations
./maincleanup.sh

# Preview what would be cleaned (recommended first run)
./maincleanup.sh --dry-run

# Run cleanup without confirmations
./maincleanup.sh --yes

# Quick cleanup with verbose output
./maincleanup.sh --quick --verbose
```

### Command Line Options

| Option | Short | Description |
|--------|-------|-------------|
| `--help` | `-h` | Display help message and exit |
| `--dry-run` | `-n` | Show what would be cleaned without actually cleaning |
| `--yes` | `-y` | Skip confirmation prompts and proceed automatically |
| `--verbose` | `-v` | Enable verbose output during cleanup |
| `--quick` | `-q` | Perform quick cleanup (basic items only) |
| `--version` | | Display script version information |

### Common Usage Examples

```bash
# First time usage - see what would be cleaned
./maincleanup.sh --dry-run --verbose

# Safe interactive cleanup
./maincleanup.sh

# Automated cleanup for scripts/cron jobs
./maincleanup.sh --yes --quick

# Verbose cleanup with confirmations
./maincleanup.sh --verbose

# Dry run of quick mode
./maincleanup.sh --dry-run --quick
```

## What Gets Cleaned

### 1. User Caches (`~/Library/Caches`)
- Application cache files
- Browser caches
- System temporary files
- **Safety**: Critical caches (Safari, Mail, Photos) are backed up before removal

### 2. Downloads Folder (`~/Downloads`)
- All files and folders in Downloads
- **Warning**: Permanently deletes all downloads - backup important files first

### 3. Trash (`~/.Trash`)
- Permanently deletes all trashed items
- **Warning**: Items cannot be recovered after permanent deletion

## Safety Features

### Critical Cache Backup
The script automatically backs up critical application caches before deletion:
- Safari (`com.apple.Safari`)
- Mail (`com.apple.mail`) 
- Photos (`com.apple.Photos`)
- iPhoto (`com.apple.iPhoto`)

Backups are stored in `~/.cleanup_backup/caches_YYYYMMDD_HHMMSS/`

### Confirmation Prompts
- Individual confirmation for each cleanup operation
- Shows file counts and sizes before deletion
- Can be bypassed with `--yes` flag for automation

### Dry-Run Mode
- Preview all operations without making changes
- Shows what files/folders would be affected
- Displays size calculations and file counts
- Perfect for understanding impact before cleanup

## Requirements

- **macOS**: 10.12 (Sierra) or later
- **Permissions**: Standard user permissions (no admin required)
- **Disk Space**: Sufficient space for temporary backup operations
- **Shell**: bash (included with macOS)

## Installation

1. **Download**: Copy `cleanup.sh` to your desired location
2. **Make Executable**: 
   ```bash
   chmod +x cleanup.sh
   ```
3. **Test**: Run a dry-run first:
   ```bash
   ./cleanup.sh --dry-run
   ```

## Output Examples

### Dry-Run Output
```
[DRY RUN] Starting cleanup preview...

=== USER CACHES ===
Current cache directory size: 2.1GB
Total files in cache directory: 15,432
[DRY RUN] Would remove contents of: /Users/jonathan/Library/Caches
[DRY RUN] Would delete 15,432 files (2.1GB)

=== DOWNLOADS FOLDER ===
Current Downloads size: 543MB
Total items in Downloads: 23
[DRY RUN] Would delete contents of: /Users/jonathan/Downloads
[DRY RUN] Would delete 23 items (543MB)

=== TRASH ===
Current Trash size: 1.2GB
Total files in Trash: 89
[DRY RUN] Would permanently delete contents of: /Users/jonathan/.Trash
[DRY RUN] Would delete 89 files (1.2GB)
```

### Actual Cleanup Output
```
=== CLEANING USER CACHES ===
Current cache directory size: 2.1GB
Clean user caches in /Users/jonathan/Library/Caches? This will remove 15,432 files (2.1GB) (y/N): y
Backing up critical caches...
  ✓ Cleaned: com.apple.Safari
  ✓ Cleaned: com.google.Chrome
  ✓ Cleaned: com.spotify.client
User cache cleanup completed.
  Previous size: 2.1GB
  Current size: 125MB
  Space freed: ~2.0GB
```

## Troubleshooting

### Common Issues

**Permission Denied Errors**
- Some cache files may be locked by running applications
- Solution: Quit applications before running cleanup

**"No such file or directory"**
- Normal when directories are already clean
- Not an error - script continues with other operations

**Backup Failed Warnings**
- Some critical caches may fail to backup if in use
- Script continues but warns about failed backups

### Verbose Mode
Use `--verbose` flag to see detailed operation logs:
```bash
./cleanup.sh --verbose
```

This shows:
- Timestamp for each operation
- Individual file operations
- Detailed error messages
- Configuration settings

## Best Practices

### Before Running
1. **Quit Applications**: Close browsers, mail, and other apps
2. **Backup Important Downloads**: Save any needed files from Downloads
3. **Run Dry-Run First**: Always preview with `--dry-run`
4. **Check Disk Space**: Ensure sufficient space for backups

### Regular Maintenance
- Run monthly for optimal performance
- Use `--quick` mode for weekly maintenance  
- Monitor freed space with `--verbose`
- Keep backup directory clean (manual cleanup needed)

### Automation
For automated cleanup (cron jobs, etc.):
```bash
# Safe automated cleanup
./cleanup.sh --yes --quick

# Full automated cleanup (more aggressive)
./cleanup.sh --yes
```

## Version Information

- **Current Version**: 1.0.0
- **License**: MIT License
- **Compatibility**: macOS 10.12+

## Disclaimer

⚠️ **Important Safety Notice**

This script is provided "as is" without warranty of any kind. While it includes safety features:

- **Always backup important data** before running system cleanup operations
- **Test with dry-run mode** before actual cleanup
- **Verify Downloads folder** doesn't contain important files
- **Understand that Trash deletion is permanent**

The author is not responsible for any data loss or system issues that may occur from using this script.

## Support

For issues, suggestions, or contributions:
1. Test with `--dry-run --verbose` first
2. Check the troubleshooting section
3. Review error messages carefully
4. Ensure macOS compatibility

---

*Last updated: July 28, 2025*
*Script version: 1.0.0*
