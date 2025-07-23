# Calendar Permissions Checker

## Overview
This PowerShell script checks calendar permissions for a specific user across all mailboxes in Exchange Online. It generates a comprehensive report showing which calendars the target user has access to and their permission levels.

## Files
- `permissionscheck.ps1` - Main script for checking calendar permissions

## Requirements
- PowerShell 5.1 or later
- ExchangeOnlineManagement module
- Exchange Online administrator permissions

## Installation
```powershell
Install-Module -Name ExchangeOnlineManagement -Force
```

## Usage
1. Run the script:
   ```powershell
   .\permissionscheck.ps1
   ```
2. When prompted, enter the email address of the user to check permissions for
3. The script will authenticate to Exchange Online
4. Results will be exported to `CalendarPermissionsReport.csv`

## Features
- Connects to Exchange Online automatically
- Retrieves all user mailboxes in the organization
- Checks calendar permissions for a specific target user
- Handles errors gracefully for inaccessible mailboxes
- Exports results to CSV format
- Automatically disconnects from Exchange Online when complete

## Output
The script generates a CSV file (`CalendarPermissionsReport.csv`) with the following columns:
- **Mailbox** - The UPN of the mailbox owner
- **AccessLevel** - The permission level (e.g., "Reviewer", "Editor", "Owner", or "None")

## Error Handling
- Mailboxes that cannot be accessed will show "Error Checking" in the AccessLevel column
- Warning messages are displayed for problematic mailboxes
- Script continues processing even if individual mailboxes fail

## Example Output
```
Mailbox,AccessLevel
john.doe@company.com,Reviewer
jane.smith@company.com,None
admin@company.com,Owner
```

## Security Notes
- Requires Exchange Online administrator privileges
- Uses modern authentication with MFA support
- Automatically disconnects session when complete
