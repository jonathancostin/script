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
```powershell
.\megaaudit.ps1 -AllUsersGroupId "group-id-here" -CompliantUsersGroupId "compliant-group-id-here" [-MaxDevices 10]
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
- **Module Errors**: Ensure all required PowerShell modules are installed
- **Permission Issues**: Verify admin consent for all required Graph API permissions
- **Report Directories**: Ensure specified output directory exists and is writable
- **Large Datasets**: Monitor memory usage and consider processing in batches for very large organizations
