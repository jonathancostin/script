# Mailbox Audit Script

## Overview
This PowerShell script performs comprehensive auditing of Exchange Online mailboxes, generating detailed reports on mailbox sizes, usage statistics, retention policies, and configuration settings across the organization.

## Files
- `MailboxAudit.ps1` - Main mailbox auditing script

## Requirements
- PowerShell 5.1 or later
- ExchangeOnlineManagement module
- Exchange Online administrator permissions

## Installation
```powershell
Install-Module -Name ExchangeOnlineManagement -Force
```

## Usage

### Prerequisites - Authentication
Make sure you have connected to Exchange Online before executing this script:

```powershell
# Connect to Exchange Online
Connect-ExchangeOnline
```

### Basic Usage
Run the following command to generate a comprehensive mailbox audit:

```powershell
.\MailboxAudit.ps1
```

## Features
- **Comprehensive Mailbox Inventory**: Audits all user mailboxes in the organization
- **Size Analysis**: Reports mailbox and archive sizes with usage statistics
- **Activity Monitoring**: Tracks last logon times and usage patterns
- **Policy Reporting**: Documents retention policies and compliance settings
- **Archive Status**: Reports archive mailbox enablement and configuration
- **CSV Export**: Generates detailed reports in CSV format for analysis

## Data Collected

### Mailbox Information
- **Display Name**: User's display name
- **Primary SMTP Address**: Primary email address
- **Mailbox Type**: UserMailbox, SharedMailbox, etc.
- **Organizational Unit**: AD organizational unit

### Size and Usage Statistics
- **Mailbox Size**: Total mailbox size in human-readable format
- **Archive Size**: Archive mailbox size (if enabled)
- **Item Count**: Number of items in primary mailbox
- **Archive Item Count**: Number of items in archive
- **Deleted Item Size**: Size of deleted items folder

### Activity and Access
- **Last Logon Time**: Most recent mailbox access
- **Last Sent Message**: Date of last sent email
- **Creation Date**: When the mailbox was created
- **Usage Statistics**: Mailbox activity patterns

### Configuration and Policies
- **Archive Status**: Enabled/Disabled
- **Retention Policy**: Applied retention policy name
- **Litigation Hold**: Hold status and settings
- **Forwarding Rules**: Email forwarding configuration
- **Quota Settings**: Mailbox size limits and warnings

## Output Format
The script generates a timestamped CSV file with comprehensive mailbox data:
```
MailboxAudit_20240123_143022.csv
```

### Sample Output Columns
```csv
DisplayName,PrimarySmtpAddress,MailboxSize,ArchiveSize,ItemCount,LastLogonTime,ArchiveStatus,RetentionPolicy,LitigationHold
John Doe,john.doe@company.com,"2.5 GB","1.2 GB",15420,2024-01-20 14:30:22,Active,Corporate Retention,Enabled
Jane Smith,jane.smith@company.com,"1.8 GB",N/A,9832,2024-01-22 09:15:10,None,Standard Policy,Disabled
```

## Use Cases
- **Capacity Planning**: Analyze storage usage across the organization
- **Compliance Auditing**: Document retention policies and legal hold status
- **Usage Analysis**: Identify inactive or underutilized mailboxes
- **Migration Planning**: Assess mailbox sizes before migrations
- **Cost Optimization**: Identify opportunities for storage optimization

## Process Flow
1. **Authentication**: Connects to Exchange Online
2. **Mailbox Discovery**: Retrieves all user mailboxes
3. **Data Collection**: Gathers comprehensive statistics for each mailbox
4. **Size Calculation**: Converts sizes to human-readable formats
5. **Policy Analysis**: Documents applied policies and settings
6. **Report Generation**: Exports all data to CSV format

## Performance Considerations
- **Large Organizations**: Processing time scales with mailbox count
- **API Throttling**: Includes retry logic for Exchange Online limits
- **Memory Usage**: Large organizations may require significant memory
- **Network Connectivity**: Stable connection required throughout execution

## Size Reporting
The script converts raw byte values to human-readable formats:
- **Bytes**: 1,024 bytes
- **KB**: 1,024² bytes  
- **MB**: 1,024³ bytes
- **GB**: 1,024⁴ bytes
- **TB**: 1,024⁵ bytes
- **PB**: 1,024⁶ bytes

## Mailbox Types Supported
- **User Mailboxes**: Standard user mailboxes
- **Shared Mailboxes**: Shared mailboxes with special handling
- **Room Mailboxes**: Conference room resources
- **Equipment Mailboxes**: Equipment resources
- **Archive Mailboxes**: In-place archive reporting

## Error Handling
- **Connection Issues**: Ensure that the ExchangeOnlineManagement module is updated. Verify login credentials and MFA settings.
- **Permission Errors**: Ensure Exchange Administrator rights are assigned.
- **Data Retrieval**: Continues processing when individual mailboxes fail with warning messages logged.
- **Large Datasets**: Handles organizations with thousands of mailboxes but may require increased memory allocation for large result sets.

## Security Considerations
- **Administrative Access**: Requires Exchange Online admin permissions
- **Sensitive Information**: Reports contain organizational mailbox data
- **Data Protection**: Secure storage and access control for reports
- **Audit Trails**: Maintains logs of audit activities

## Customization Options
- **Mailbox Filters**: Modify script to filter specific mailbox types
- **Data Fields**: Add or remove columns from the output
- **Size Thresholds**: Set custom size reporting thresholds
- **Date Ranges**: Filter based on creation or activity dates

## Integration
- **PowerBI**: Import CSV data for advanced analytics and dashboards
- **Excel**: Direct import for organizational reporting
- **Compliance Tools**: Export data for compliance management systems
- **Monitoring Systems**: Integrate with IT monitoring platforms

## Troubleshooting
- **Module Issues**: Verify ExchangeOnlineManagement module installation
- **Permission Problems**: Ensure adequate Exchange Online permissions
- **Memory Errors**: Consider processing in smaller batches for large organizations
- **Output Issues**: Verify write permissions for output directory

## Best Practices
- **Regular Auditing**: Run monthly or quarterly for trend analysis
- **Data Retention**: Maintain historical reports for comparison
- **Security**: Store reports in secure, access-controlled locations
- **Documentation**: Document any customizations or filtering applied
