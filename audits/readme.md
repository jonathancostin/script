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
   # Core modules required for all scripts
   Install-Module ExchangeOnlineManagement -Force
   Install-Module Microsoft.Graph -Force
   
   # Specific Graph modules (installed automatically by scripts if missing)
   Install-Module Microsoft.Graph.Users -Force
   Install-Module Microsoft.Graph.Groups -Force
   Install-Module Microsoft.Graph.DeviceManagement -Force
   ```
2. Ensure you have appropriate permissions in Microsoft 365:
   - Exchange Administrator (for mailbox operations)
   - Global Reader or User Administrator (for user data)
   - Intune Administrator (for device compliance data)
3. Configure admin consent for Microsoft Graph permissions
4. Run scripts with administrative privileges

## Scripts Overview

Brief description of each script included in the project:

| Script Directory | Script Name | Purpose | Main Function |
|------------------|-------------|---------|---------------|
| mailboxaudit/ | MailboxAudit.ps1 | Audits mailbox sizes across Exchange Online | Generates comprehensive mailbox size reports including primary and archive mailboxes |
| megaaudit/ | megaaudit.ps1 | Comprehensive user compliance and device audit | Performs multi-service audit including user activity, MFA status, and Intune compliance |
| officeaudits/ | o365Reporter.ps1 | User activity and MFA reporting | Analyzes user sign-in activity, license assignments, MFA status, and device enrollment |
| intuneaudits/ | IntuneComplianceAudit.ps1 | Intune device compliance auditing | Reports on device compliance status for users in specified groups |

## Usage

### Prerequisites - Authentication
All scripts require proper authentication to Microsoft services before execution:

```powershell
# Connect to Microsoft Graph (required for most scripts)
Connect-MgGraph -Scopes "User.Read.All", "DeviceManagementManagedDevices.Read.All", "Directory.Read.All", "GroupMember.Read.All", "UserAuthenticationMethod.Read.All"

# Connect to Exchange Online (required for mailbox operations)
Connect-ExchangeOnline
```

### Basic Usage
```powershell
# Basic mailbox audit (requires Exchange Online connection)
Connect-ExchangeOnline
.\mailboxaudit\MailboxAudit.ps1

# Comprehensive mega audit (requires both Graph and Exchange connections)
Connect-MgGraph -Scopes "User.Read.All", "DeviceManagementManagedDevices.Read.All", "Directory.Read.All", "GroupMember.Read.All", "UserAuthenticationMethod.Read.All"
Connect-ExchangeOnline
.\megaaudit\megaaudit.ps1 -AllUsersGroupId "group-id" -CompliantUsersGroupId "compliant-group-id"

# Office 365 Reporter (user activity and MFA reporting)
Connect-MgGraph -Scopes "User.Read.All", "DeviceManagementManagedDevices.Read.All", "Directory.Read.All", "UserAuthenticationMethod.Read.All", "AuditLog.Read.All"
Connect-ExchangeOnline
.\officeaudits\o365Reporter.ps1

# Intune Compliance Audit
Connect-MgGraph -Scopes "User.Read.All", "GroupMember.Read.All", "DeviceManagementManagedDevices.Read.All"
.\intuneaudits\IntuneComplianceAudit.ps1 -AllUsersGroupId "group-id" -CompliantUsersGroupId "compliant-group-id"
```

### Examples with Full Connection Commands
```powershell
# Example 1: Basic mailbox audit
Connect-ExchangeOnline
.\mailboxaudit\MailboxAudit.ps1

# Example 2: Mega audit with specific groups
Connect-MgGraph -Scopes "User.Read.All", "DeviceManagementManagedDevices.Read.All", "Directory.Read.All", "GroupMember.Read.All", "UserAuthenticationMethod.Read.All", "AuditLog.Read.All", "Policy.Read.All"
Connect-ExchangeOnline
.\megaaudit\megaaudit.ps1 -AllUsersGroupId "12345-abcd-67890" -CompliantUsersGroupId "67890-efgh-12345"

# Example 3: Mega audit with custom device limit
Connect-MgGraph -Scopes "User.Read.All", "DeviceManagementManagedDevices.Read.All", "Directory.Read.All", "GroupMember.Read.All", "UserAuthenticationMethod.Read.All", "AuditLog.Read.All", "Policy.Read.All"
Connect-ExchangeOnline
.\megaaudit\megaaudit.ps1 -AllUsersGroupId "12345-abcd-67890" -CompliantUsersGroupId "67890-efgh-12345" -MaxDevices 15

# Example 4: Intune compliance audit
Connect-MgGraph -Scopes "User.Read.All", "GroupMember.Read.All", "DeviceManagementManagedDevices.Read.All"
.\intuneaudits\IntuneComplianceAudit.ps1 -AllUsersGroupId "12345-abcd-67890" -CompliantUsersGroupId "67890-efgh-12345" -MaxDevices 20
```

## Parameters

### Required Parameters by Script

#### megaaudit.ps1
| Parameter | Description | Type | Example |
|-----------|-------------|------|---------|
| AllUsersGroupId | ID of the group containing all users to audit | string | `"12345-abcd-67890"` |
| CompliantUsersGroupId | ID of the compliant users group | string | `"67890-efgh-12345"` |

#### IntuneComplianceAudit.ps1
| Parameter | Description | Type | Example |
|-----------|-------------|------|---------|
| AllUsersGroupId | ID of the group containing all users to audit | string | `"12345-abcd-67890"` |
| CompliantUsersGroupId | ID of the group used for conditional access compliance | string | `"67890-efgh-12345"` |

### Optional Parameters

#### megaaudit.ps1 & IntuneComplianceAudit.ps1
| Parameter | Description | Type | Default | Example |
|-----------|-------------|------|---------|---------|
| MaxDevices | Maximum number of devices to report per user | integer | 10 | `-MaxDevices 15` |

#### IntuneComplianceAudit.ps1
| Parameter | Description | Type | Default | Example |
|-----------|-------------|------|---------|---------|
| OutputFile | Custom output file path | string | Auto-generated | `-OutputFile "C:\Reports\IntuneAudit.csv"` |

### Parameter Details
- **AllUsersGroupId**: The Azure AD group ID containing all users you want to include in the audit
- **CompliantUsersGroupId**: The dynamic group ID used for Intune compliance enforcement or conditional access
- **MaxDevices**: Controls how many device columns are included in the output CSV
- **OutputFile**: Allows custom naming of output files (IntuneComplianceAudit.ps1 only)

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

#### Authentication Issues
1. **Issue**: "Connect-ExchangeOnline failed"
   - **Solution**: 
     ```powershell
     # Update Exchange Online Management module
     Update-Module ExchangeOnlineManagement -Force
     
     # Try connecting with specific tenant
     Connect-ExchangeOnline -Organization "yourtenant.onmicrosoft.com"
     ```
   - Verify Exchange administrator permissions
   - Check network connectivity and firewall settings
   - Ensure MFA is properly configured for admin account

2. **Issue**: "Connect-MgGraph authentication failed"
   - **Solution**:
     ```powershell
     # Clear cached credentials
     Disconnect-MgGraph
     
     # Reconnect with explicit scopes
     Connect-MgGraph -Scopes "User.Read.All", "Directory.Read.All" -TenantId "your-tenant-id"
     ```
   - Ensure admin consent has been granted for required permissions
   - Verify conditional access policies aren't blocking the connection

3. **Issue**: "Insufficient privileges to complete the operation"
   - **Solution**: Verify the following roles are assigned:
     - Exchange Administrator (for mailbox operations)
     - Global Reader or User Administrator (for user data)
     - Intune Administrator (for device compliance data)

#### Data Retrieval Issues
4. **Issue**: "Failed to retrieve MFA for user"
   - **Solution**: 
     ```powershell
     # Test Graph permissions
     Get-MgUser -Top 1 -Select "id,displayName"
     
     # Verify required scope
     Connect-MgGraph -Scopes "UserAuthenticationMethod.Read.All"
     ```
   - Check if user account has appropriate Graph API permissions
   - Ensure the authentication methods policy allows querying MFA status

5. **Issue**: "No mailbox found for user"
   - **Solution**: Some users may not have mailboxes assigned
     ```powershell
     # Check if user has a mailbox
     Get-Recipient -Identity "user@domain.com" -ErrorAction SilentlyContinue
     ```
   - This is normal for unlicensed users or those without Exchange licenses

6. **Issue**: "Device information not available"
   - **Solution**: 
     ```powershell
     # Verify Intune connection
     Get-MgDeviceManagementManagedDevice -Top 1
     ```
   - Ensure devices are enrolled in Intune
   - Check that DeviceManagementManagedDevices.Read.All permission is granted

#### Performance Issues
7. **Issue**: Large datasets causing timeouts
   - **Solution**: Process in smaller batches or during off-peak hours
     ```powershell
     # For large organizations, consider filtering
     $Users = Get-MgUser -Filter "accountEnabled eq true" -Top 100
     ```
   - Increase timeout values if possible
   - Consider running against specific user groups rather than entire tenant

8. **Issue**: "Script running slowly"
   - **Solution**: 
     - Run during off-peak hours when API throttling is less likely
     - Implement retry logic for throttled requests
     - Consider parallel processing for large datasets (use with caution)

#### Output and Reporting Issues
9. **Issue**: "CSV file is empty or incomplete"
   - **Solution**: 
     ```powershell
     # Check if variables contain data before export
     Write-Host "Users found: $($Users.Count)"
     
     # Verify export path is writable
     Test-Path -Path "C:\Reports" -PathType Container
     ```
   - Ensure output directory exists and is writable
   - Check for errors during data collection that might prevent export

10. **Issue**: "Special characters in output causing issues"
    - **Solution**: 
      ```powershell
      # Use UTF-8 encoding for international characters
      $Results | Export-Csv -Path "report.csv" -NoTypeInformation -Encoding UTF8
      ```
    - Clean data before export to remove problematic characters

### Version History
- v1.0.0: Initial MailboxAudit.ps1 release
- v2.0.0: Added megaaudit.ps1 comprehensive auditing
- v2.1.0: Enhanced error handling and progress reporting

### Contact Information
- Author: Jonathan Costin
- Repository: [10Scripts Project]
- Issues: Contact author for support
