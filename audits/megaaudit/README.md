# Mega Audit Script

## Overview
This comprehensive PowerShell script performs a multi-faceted audit of Microsoft 365 users, mailboxes, and Intune device compliance. It generates detailed reports on user activity, licensing, MFA status, device enrollment, and mailbox statistics.

## Files
- `megaaudit.ps1` - Main comprehensive audit script

## Requirements
- PowerShell 5.1 or later
- Microsoft Graph PowerShell modules:
  - `Microsoft.Graph.Users`
  - `Microsoft.Graph.Groups` 
  - `Microsoft.Graph.DeviceManagement`
- ExchangeOnlineManagement module
- Microsoft 365 administrator permissions

## Installation
```powershell
Install-Module -Name Microsoft.Graph -Force
Install-Module -Name ExchangeOnlineManagement -Force
```

## Usage

### Prerequisites - Authentication
Make sure you have connected to both Microsoft Graph and Exchange Online before executing this script:

```powershell
# Connect to Microsoft Graph with required scopes
Connect-MgGraph -Scopes "User.Read.All", "DeviceManagementManagedDevices.Read.All", "Directory.Read.All", "User.ReadBasic.All", "UserAuthenticationMethod.Read.All", "AuditLog.Read.All", "Policy.Read.All", "GroupMember.Read.All"

# Connect to Exchange Online
Connect-ExchangeOnline
```

### Basic Usage
Run the script with the required Group IDs:

```powershell
.\megaaudit.ps1 -AllUsersGroupId "group-id-here" -CompliantUsersGroupId "compliant-group-id-here" [-MaxDevices 10]
```

### Command Examples
```powershell
# Basic execution with required parameters
.\megaaudit.ps1 -AllUsersGroupId "12345678-1234-1234-1234-123456789012" -CompliantUsersGroupId "87654321-4321-4321-4321-210987654321"

# Execution with custom device limit
.\megaaudit.ps1 -AllUsersGroupId "12345678-1234-1234-1234-123456789012" -CompliantUsersGroupId "87654321-4321-4321-4321-210987654321" -MaxDevices 15
```

### Parameters
- **AllUsersGroupId** (Mandatory): Object ID of the group containing all users
- **CompliantUsersGroupId** (Mandatory): Object ID of the dynamic group for compliant users
- **MaxDevices** (Optional): Maximum devices per user for reporting (default: 10)

## Features
- **User Activity Analysis**: Identifies active vs. inactive users based on sign-in activity
- **License Reporting**: Maps and reports all assigned Microsoft 365 licenses
- **MFA Status Checking**: Determines MFA enablement and authentication methods
- **Device Enrollment**: Reports Intune-enrolled devices per user
- **Mailbox Statistics**: Comprehensive mailbox size and usage reporting
- **Multi-Service Integration**: Combines data from Microsoft Graph and Exchange Online

## Process Flow
1. **Authentication**: Connects to Microsoft Graph and Exchange Online
2. **User Discovery**: Retrieves all users with licensing and sign-in data
3. **Activity Classification**: Separates users into active and inactive categories
4. **MFA Analysis**: Checks authentication methods for each user
5. **Device Enumeration**: Identifies Intune-managed devices per user
6. **Mailbox Auditing**: Gathers comprehensive mailbox statistics
7. **Report Generation**: Creates CSV reports for all data categories

## Output Reports
The script generates multiple CSV files in a specified directory:

### User Reports
- **InactiveUsers.csv**: Users with no activity in the last month
- **ActiveUsers.csv**: Users with recent activity

### Mailbox Report
- **MailboxReport_[timestamp].csv**: Comprehensive mailbox statistics

## Report Contents

### Inactive Users Report
- DisplayName
- UserPrincipalName
- LastSignInDate
- LastSentMessage
- Licenses
- HasMfa
- MFAType

### Active Users Report
- DisplayName
- UserPrincipalName
- Licenses
- HasMfa
- MFAType
- Devices (Intune-enrolled device names)

### Mailbox Report
- DisplayName
- PrimarySmtpAddress
- MailboxSize
- ItemCount
- LastLogonTime
- ArchiveStatus
- RetentionPolicy
- LitigationHold
- ForwardingAddress

## MFA Detection
The script identifies:
- **Microsoft Authenticator App**: Mobile app-based authentication
- **Software OATH Tokens**: Third-party authenticator apps
- **Combined Methods**: Users with multiple MFA methods
- **SMS/None**: Users without app-based MFA

## Activity Thresholds
- **Inactive Users**: No sign-in activity in the last 30 days
- **Mailbox Activity**: Checks last sent message date for inactive users
- **External Users**: Automatically skips users with "#EXT#" in UPN

## Example Usage Session
```powershell
PS> .\megaaudit.ps1 -AllUsersGroupId "12345678-1234-1234-1234-123456789012" -CompliantUsersGroupId "87654321-4321-4321-4321-210987654321"

Enter directory where all reports will be saved: C:\AuditReports

Connecting to Microsoft Graph...
Connecting to Exchange Online...

Processing John Doe <john.doe@company.com>
Processing Jane Smith <jane.smith@company.com>
...

User reports generated:
  C:\AuditReports\InactiveUsers.csv
  C:\AuditReports\ActiveUsers.csv

Starting mailbox audit...
1,250 mailboxes found.

Processing mailbox: john.doe@company.com
Processing mailbox: jane.smith@company.com
...

Mailbox report generated:
  C:\AuditReports\MailboxReport_20240123_143022.csv
```

## Mailbox Statistics
The script collects comprehensive mailbox data:
- **Size Information**: Total mailbox size in human-readable format
- **Item Counts**: Number of items in mailboxes and archives
- **Activity Data**: Last logon times and usage patterns
- **Policy Information**: Retention policies and litigation hold status
- **Forwarding Rules**: Email forwarding configurations

## Performance Considerations
- **Large Organizations**: Processing time scales with user and mailbox count
- **API Throttling**: Script includes error handling for Microsoft Graph rate limits
- **Memory Usage**: Large datasets may require significant memory
- **Network Connectivity**: Stable internet connection required throughout execution

## Error Handling
- **Authentication Failures**: Graceful handling of connection issues
- **Missing Mailboxes**: Continues processing when users lack mailboxes
- **Permission Errors**: Reports specific permission issues for troubleshooting
- **API Limits**: Implements retry logic for rate-limited requests

## Security Considerations
- **Administrative Privileges**: Requires extensive Microsoft 365 admin permissions
- **Sensitive Data**: Reports contain comprehensive organizational information
- **Data Protection**: Ensure reports are stored securely and access-controlled
- **Compliance**: Consider data retention policies for generated reports

## Customization Options
- **Device Limits**: Adjust MaxDevices parameter for device reporting
- **Activity Thresholds**: Modify the 30-day activity window in the script
- **Report Fields**: Add or remove fields from output reports
- **Filtering Logic**: Customize user filtering criteria

## Troubleshooting

### Authentication Issues
1. **Module Errors**: 
   ```powershell
   # Install required modules if missing
   Install-Module Microsoft.Graph -Force
   Install-Module ExchangeOnlineManagement -Force
   ```

2. **Permission Issues**: 
   - Verify admin consent for all required Graph API permissions
   - Ensure the account has Exchange Administrator and Global Reader roles
   - Check that conditional access policies aren't blocking the connection

3. **Connection Failures**: 
   ```powershell
   # If authentication fails, try disconnecting and reconnecting
   Disconnect-MgGraph
   Disconnect-ExchangeOnline
   
   # Reconnect with explicit tenant ID
   Connect-MgGraph -TenantId "your-tenant-id" -Scopes "User.Read.All", "DeviceManagementManagedDevices.Read.All", "Directory.Read.All"
   Connect-ExchangeOnline -Organization "yourtenant.onmicrosoft.com"
   ```

### Data Processing Issues
4. **MFA Retrieval Errors**: 
   - Verify UserAuthenticationMethod.Read.All permission is granted
   - Some users may not have MFA configured, which is normal

5. **Mailbox Access Issues**: 
   - Some users may not have mailboxes (unlicensed users)
   - Script continues processing and logs users without mailboxes

6. **Device Information Missing**: 
   - Ensure devices are enrolled in Intune
   - Verify DeviceManagementManagedDevices.Read.All permission

### Performance and Output Issues
7. **Report Directories**: 
   - Ensure specified output directory exists and is writable
   - The script will prompt for a directory if not provided

8. **Large Datasets**: 
   - Monitor memory usage and consider processing in batches for very large organizations
   - Consider running during off-peak hours
   - For organizations with >10,000 users, consider reducing MaxDevices parameter

9. **Empty or Incomplete Reports**: 
   ```powershell
   # Check if users were processed
   Write-Host "Active users: $($ActiveResults.Count)"
   Write-Host "Inactive users: $($InactiveResults.Count)"
   ```
