# Office Scripts

## Overview

This directory contains PowerShell scripts for managing Microsoft 365 and Exchange Online environments. These scripts handle various administrative tasks including calendar permissions, distribution lists, global address lists, group management, mailbox archiving, and SharePoint permissions.

## Prerequisites

### System Requirements
- Operating System: Windows PowerShell 5.1 or PowerShell 7+
- Required software versions: Exchange Online Management, Microsoft Graph PowerShell, PnP PowerShell
- Hardware requirements: Standard Windows system with network connectivity

### Dependencies
- Programming language version: PowerShell 5.1+
- Required packages/libraries:
  - ExchangeOnlineManagement
  - Microsoft.Graph
  - PnP.PowerShell
- External tools or services: Microsoft 365 tenant with appropriate administrative permissions

### Setup Instructions
1. Install required PowerShell modules:
   ```powershell
   Install-Module ExchangeOnlineManagement -Force
   Install-Module Microsoft.Graph -Force
   Install-Module PnP.PowerShell -Force
   ```
2. Configure appropriate permissions in Microsoft 365 admin center
3. Ensure execution policy allows script execution

## Scripts Overview

Brief description of each script included in the project:

| Script Name | Purpose | Main Function |
|-------------|---------|---------------|
| permissionscheck.ps1 | Checks calendar permissions for a specific user | Reports calendar access levels across all mailboxes |
| matchdistlists.ps1 | Matches distribution list memberships between users | Adds UserA to all distribution lists that UserB belongs to |
| galexport.ps1 | Exports address lists to CSV | Generates CSV report of all address lists |
| galusers.ps1 | Exports Global Address List users | Creates CSV export of all GAL recipients |
| group.ps1 | Manages group memberships | Adds users to groups based on another user's memberships |
| setmailboxarchive.ps1 | Manages mailbox archive policies | Sets up and applies retention policies for mailbox archiving |
| report.ps1 | SharePoint permission reporting | Exports user permissions across SharePoint sites |

## Usage

### Basic Usage
```powershell
# Calendar permissions check
.\\calendars\\permissions\\permissionscheck.ps1

# Distribution list matching
.\\distlist\\matchdistlists.ps1 -UserA user1@domain.com -UserB user2@domain.com

# Export address lists
.\\gal\\galexport.ps1
```

### Examples
```powershell
# Example 1: Check calendar permissions
.\\calendars\\permissions\\permissionscheck.ps1
# Prompts for: target user email to check

# Example 2: Match distribution lists
.\\distlist\\matchdistlists.ps1 -UserA alice@company.com -UserB bob@company.com

# Example 3: Export GAL users
.\\gal\\galusers.ps1

# Example 4: Set mailbox archive policy
.\\mailarchive\\setmailboxarchive.ps1
# Interactive prompts for tag selection and mailbox identities

# Example 5: SharePoint permissions report
.\\sharepoint\\report.ps1 -Sites "https://tenant.sharepoint.com/sites/site1" -User "user@domain.com"
```

## Parameters

### Required Parameters
| Parameter | Description | Type | Example |
|-----------|-------------|------|---------|
| UserA (matchdistlists.ps1) | Source user to copy memberships from | string | `"alice@company.com"` |
| UserB (matchdistlists.ps1) | Target user to receive memberships | string | `"bob@company.com"` |
| Sites (report.ps1) | SharePoint site URLs to scan | string[] | `@("https://tenant.sharepoint.com/sites/site1")` |
| User (report.ps1) | User to check permissions for | string | `"user@domain.com"` |

### Optional Parameters
| Parameter | Description | Type | Default | Example |
|-----------|-------------|------|---------|------------|
| OutputFile (report.ps1) | Custom output file path | string | Auto-generated | `"custom_report.csv"` |

### Parameter Details
- **UserA/UserB**: Must be valid user principal names (UPNs) in the tenant
- **Sites**: Can include multiple SharePoint site collection URLs
- **User**: The user principal name to check permissions for across SharePoint sites
- **OutputFile**: If not specified, generates timestamp-based filename

## Output Description

### Output Format
Description of the expected output format(s):
- CSV files for most reports
- Console output with colored status messages
- Structured data with headers and proper formatting

### Output Locations
- **permissionscheck.ps1**: `CalendarPermissionsReport.csv` in current directory
- **galexport.ps1**: `~/all-addresslists.csv` in user's home directory
- **galusers.ps1**: `~/gal-emails.csv` in user's home directory
- **report.ps1**: `SPPermissions_<User>_<timestamp>.csv` or custom path

### Success Indicators
- Successful connection messages to Office 365 services
- Progress updates during processing
- Confirmation of file exports with file paths
- Clean disconnection from services

### Error Handling
- Connection failures are caught and reported
- Individual item processing errors are logged but don't stop execution
- Missing permissions result in warning messages
- Graceful handling of non-existent users or groups

## Special Notes

### Important Considerations
- All scripts require appropriate Microsoft 365 administrator permissions
- Network connectivity to Microsoft 365 services is required
- Some operations may take significant time for large organizations
- Scripts modify permissions and group memberships - use with caution

### Known Limitations
- External users may not appear in some reports
- SharePoint permissions reporting requires site collection admin rights
- Distribution list operations are limited to Exchange Online (not on-premises)
- Archive policy changes may take time to propagate

### Best Practices
- Test scripts in non-production environments first
- Use service accounts with minimal required permissions
- Run during maintenance windows for organization-wide changes
- Keep audit logs of permission changes
- Validate user inputs before bulk operations

### Troubleshooting
Common issues and their solutions:

1. **Issue**: "Connect-ExchangeOnline failed"
   - **Solution**: Verify Exchange Online Management module is current
   - Check account has Exchange administrator role
   - Ensure modern authentication is enabled

2. **Issue**: SharePoint connection errors
   - **Solution**: Install latest PnP.PowerShell module
   - Verify SharePoint administrator permissions
   - Check site collection URLs are correct and accessible

3. **Issue**: Graph API permission errors
   - **Solution**: Ensure Microsoft Graph PowerShell has required consent
   - Verify admin has granted appropriate API permissions
   - Re-run Connect-MgGraph with necessary scopes

### Version History
- v1.0.0: Initial calendar permissions and GAL export scripts
- v1.1.0: Added distribution list matching functionality
- v1.2.0: Enhanced group management capabilities
- v1.3.0: Added mailbox archive policy management
- v1.4.0: Integrated SharePoint permissions reporting

### Contact Information
- Author: Jonathan Costin
- Repository: [10Scripts Project]
- Issues: Contact author for support and feature requests
