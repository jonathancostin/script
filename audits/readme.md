# Audits Scripts

## Overview

This directory contains PowerShell scripts for auditing Microsoft 365 and Exchange Online environments. These scripts help administrators assess mailbox usage, user compliance, and generate comprehensive reports.

## Prerequisites

### System Requirements
- Operating System: Windows PowerShell 5.1 or PowerShell 7+
- Required software versions: Exchange Online Management module, Microsoft Graph PowerShell
- Hardware requirements: Sufficient memory for processing large user datasets

### Dependencies
- Programming language version: PowerShell 5.1+
- Required packages/libraries:
  - ExchangeOnlineManagement
  - Microsoft.Graph.Users
  - Microsoft.Graph.Groups
  - Microsoft.Graph.DeviceManagement
- External tools or services: Microsoft 365 tenant with appropriate permissions

### Setup Instructions
1. Install required PowerShell modules:
   ```powershell
   Install-Module ExchangeOnlineManagement -Force
   Install-Module Microsoft.Graph -Force
   ```
2. Ensure you have appropriate permissions in Microsoft 365
3. Run scripts with administrative privileges

## Scripts Overview

Brief description of each script included in the project:

| Script Name | Purpose | Main Function |
|-------------|---------|---------------|
| MailboxAudit.ps1 | Audits mailbox sizes across Exchange Online | Generates comprehensive mailbox size reports including primary and archive mailboxes |
| megaaudit.ps1 | Comprehensive user compliance and device audit | Performs multi-service audit including user activity, MFA status, and Intune compliance |

## Usage

### Basic Usage
```powershell
# Basic mailbox audit
.\MailboxAudit.ps1

# Comprehensive mega audit
.\megaaudit.ps1 -AllUsersGroupId "group-id" -CompliantUsersGroupId "compliant-group-id"
```

### Examples
```powershell
# Example 1: Basic mailbox audit
.\MailboxAudit.ps1

# Example 2: Mega audit with specific groups
.\megaaudit.ps1 -AllUsersGroupId "12345-abcd-67890" -CompliantUsersGroupId "67890-efgh-12345"

# Example 3: Mega audit with custom device limit
.\megaaudit.ps1 -AllUsersGroupId "12345-abcd-67890" -CompliantUsersGroupId "67890-efgh-12345" -MaxDevices 15
```

## Parameters

### Required Parameters (megaaudit.ps1)
| Parameter | Description | Type | Example |
|-----------|-------------|------|---------|
| AllUsersGroupId | ID of the group containing all users to audit | string | `"12345-abcd-67890"` |
| CompliantUsersGroupId | ID of the compliant users group | string | `"67890-efgh-12345"` |

### Optional Parameters (megaaudit.ps1)
| Parameter | Description | Type | Default | Example |
|-----------|-------------|------|---------|---------|
| MaxDevices | Maximum number of devices to report per user | integer | 10 | `-MaxDevices 15` |

### Parameter Details
- **AllUsersGroupId**: The Azure AD group ID containing all users you want to include in the audit
- **CompliantUsersGroupId**: The dynamic group ID used for Intune compliance enforcement
- **MaxDevices**: Controls how many device columns are included in the output CSV

## Output Description

### Output Format
Description of the expected output format(s):
- CSV files with comprehensive audit data
- Mailbox size reports with readable size formats
- User activity and compliance status reports
- Device enrollment and compliance information

### Output Locations
- MailboxAudit.ps1: Prompts for custom report path, saves settings for reuse
- megaaudit.ps1: Prompts for base directory, creates multiple reports:
  - InactiveUsers.csv
  - ActiveUsers.csv
  - MailboxReport_[timestamp].csv
  - IntuneComplianceAudit_[tenant]_[timestamp].csv

### Success Indicators
- Green status messages during execution
- Successful CSV file generation
- Connection confirmations to required services
- Progress indicators for large datasets

### Error Handling
- Connection failures are logged with specific error messages
- Individual user processing errors are caught and logged
- Graceful handling of missing mailboxes or permissions
- Retry logic for API rate limiting

## Special Notes

### Important Considerations
- Scripts require significant Microsoft 365 permissions
- Processing time increases with organization size
- Network connectivity required for cloud service connections
- Some operations may trigger security alerts in monitored environments

### Known Limitations
- External users are automatically skipped in megaaudit.ps1
- Archive mailbox reporting requires archive to be enabled
- Device information limited to Intune-managed devices
- MFA status detection limited to specific authentication methods

### Best Practices
- Run during off-peak hours for large organizations
- Ensure stable network connectivity
- Use service accounts with appropriate permissions
- Review output files for sensitive information before sharing

### Troubleshooting
Common issues and their solutions:

1. **Issue**: "Connect-ExchangeOnline failed"
   - **Solution**: Verify Exchange Online Management module is installed and up to date
   - Check network connectivity and firewall settings
   - Ensure account has Exchange administrator permissions

2. **Issue**: "Failed to retrieve MFA for user"
   - **Solution**: Verify Microsoft Graph permissions include UserAuthenticationMethod.Read.All
   - Check if user account has appropriate Graph API permissions

3. **Issue**: Large datasets causing timeouts
   - **Solution**: Process in smaller batches or during off-peak hours
   - Increase timeout values if possible
   - Consider running against specific user groups rather than entire tenant

### Version History
- v1.0.0: Initial MailboxAudit.ps1 release
- v2.0.0: Added megaaudit.ps1 comprehensive auditing
- v2.1.0: Enhanced error handling and progress reporting

### Contact Information
- Author: Jonathan Costin
- Repository: [10Scripts Project]
- Issues: Contact author for support
