# Script Analysis Report
*Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')*

## Overview
This report analyzes 27 scripts across multiple categories within your script collection. Each script has been reviewed for functionality, parameters, prerequisites, and dependencies.

---

## Audit Scripts

### 1. IntuneComplianceAudit.ps1
**Location:** `/users/jonathan/files/10scripts/audits/intuneaudits/`
**Purpose:** Audits Microsoft Intune device compliance across user groups

**Parameters:**
- `AllUsersGroupId` (Required) - ID of the group containing all users
- `CompliantUsersGroupId` (Required) - ID of compliant users group  
- `MaxDevices` (Optional, default: 10) - Maximum devices to report per user
- `OutputFile` (Optional) - Output CSV filename with automatic timestamp

**Prerequisites:**
- PowerShell module: Microsoft.Graph.DeviceManagement
- PowerShell module: Microsoft.Graph.Groups  
- PowerShell module: Microsoft.Graph.Users
- Graph permissions: User.Read.All, GroupMember.Read.All, DeviceManagementManagedDevices.Read.All

**Dependencies:** Auto-installs missing Graph modules
**Usage:** For compliance auditing across organizational groups

---

### 2. MailboxAudit.ps1
**Location:** `/users/jonathan/files/10scripts/audits/mailboxaudit/`
**Purpose:** Generates comprehensive mailbox size reports including archive data

**Parameters:**
- Interactive prompts for report path storage
- Remembers previous report locations via settings file

**Prerequisites:**
- PowerShell module: ExchangeOnlineManagement
- Exchange Online connection: `Connect-ExchangeOnline`

**Dependencies:** Exchange Online Management module
**Usage:** Mailbox storage analysis and reporting

---

### 3. megaaudit.ps1
**Location:** `/users/jonathan/files/10scripts/audits/megaaudit/`
**Purpose:** Comprehensive M365 audit combining user activity, mailbox data, and Intune compliance

**Parameters:**
- `AllUsersGroupId` (Required) - All users group ID
- `CompliantUsersGroupId` (Required) - Compliant users group ID
- `MaxDevices` (Optional, default: 10) - Max devices per user
- Interactive prompt for base report directory

**Prerequisites:**
- PowerShell modules: Microsoft.Graph.Users, Microsoft.Graph.Groups, Microsoft.Graph.DeviceManagement
- Connections: `Connect-MgGraph`, `Connect-ExchangeOnline`
- Graph permissions: User.Read.All, DeviceManagementManagedDevices.Read.All, Directory.Read.All, UserAuthenticationMethod.Read.All, AuditLog.Read.All, Policy.Read.All, GroupMember.Read.All

**Dependencies:** Multiple Graph modules, Exchange Online Management
**Usage:** Complete organizational audit including inactive users, mailbox sizes, and device compliance

---

### 4. o365Reporter.ps1
**Location:** `/users/jonathan/files/10scripts/audits/officeaudits/`
**Purpose:** Office 365 user activity reporting with MFA status and device enrollment

**Parameters:** None (hardcoded execution)

**Prerequisites:**
- PowerShell module: Microsoft.Graph
- PowerShell module: ExchangeOnlineManagement
- Connections: `Connect-MgGraph`, `Connect-ExchangeOnline`
- Graph permissions: User.Read.All, DeviceManagementManagedDevices.Read.All, Directory.Read.All, UserAuthenticationMethod.Read.All, AuditLog.Read.All, Policy.Read.All

**Dependencies:** Graph and Exchange modules
**Usage:** User activity analysis including sign-in patterns and MFA compliance

---

### Version Scripts (audits/officeaudits/versions/)

#### 5. 2LoginMainWorkingwithmfa.ps1
**Purpose:** Enhanced login analysis with MFA checking (work in progress)
**Prerequisites:** Same as o365Reporter.ps1
**Usage:** Development version with MFA enhancements

#### 6. LoginMainWorking.ps1  
**Purpose:** Basic login analysis (legacy version)
**Prerequisites:** Microsoft.Graph module
**Usage:** Basic user login reporting

#### 7. pw.ps1
**Purpose:** Password-focused user analysis
**Prerequisites:** Same as o365Reporter.ps1 plus password change data
**Usage:** Comprehensive user data including password change tracking

---

## macOS Cleanup Scripts

### 8. clean_xcode_derived_data.zsh
**Location:** `/users/jonathan/files/10scripts/mac/cleanup/`
**Purpose:** Safely cleans Xcode DerivedData directory

**Parameters:**
- `-d, --dry-run` - Preview mode without deletion
- `-f, --force` - Skip confirmation prompts  
- `-h, --help` - Show usage information

**Prerequisites:**
- macOS with Xcode installed
- zsh shell (default on macOS)
- xcode-select tools configured

**Dependencies:** Standard macOS commands (du, find, rm)
**Usage:** `./clean_xcode_derived_data.zsh --dry-run`

---

### 9. cleanup-downloads.sh
**Location:** `/users/jonathan/files/10scripts/mac/cleanup/`
**Purpose:** Cleans old files from Downloads folder

**Parameters:**
- `--dry-run` - List files without deleting
- `--days N` - Set age threshold (default: 30 days)
- `--help` - Show help

**Prerequisites:**
- macOS/Linux with zsh
- Standard UNIX utilities

**Dependencies:** find, ls, numfmt
**Usage:** `./cleanup-downloads.sh --dry-run --days 60`

---

### 10. cleanup_dry_run.sh
**Location:** `/users/jonathan/files/10scripts/mac/cleanup/`
**Purpose:** Preview cleanup operations across multiple cache locations

**Parameters:** None (preview only)

**Prerequisites:** 
- macOS system
- zsh shell

**Dependencies:** Standard shell utilities
**Usage:** `./cleanup_dry_run.sh`

---

### 11. cleanup_full.sh
**Location:** `/users/jonathan/files/10scripts/mac/cleanup/`
**Purpose:** Comprehensive cleanup of browser caches and downloads

**Parameters:** Interactive confirmation required

**Prerequisites:**
- macOS system
- zsh shell

**Dependencies:** Standard file operations
**Usage:** `./cleanup_full.sh` (with interactive confirmation)

---

### 12. cleanup_old_logs.sh
**Location:** `/users/jonathan/files/10scripts/mac/cleanup/`
**Purpose:** Removes old log files from ~/Library/Logs

**Parameters:**
- Command line: `./cleanup_old_logs.sh [days]`
- Environment variable: `LOG_CLEANUP_DAYS`

**Prerequisites:**
- macOS system
- zsh shell

**Dependencies:** find command
**Usage:** `LOG_CLEANUP_DAYS=14 ./cleanup_old_logs.sh`

---

### 13. maincleanup.sh
**Location:** `/users/jonathan/files/10scripts/mac/cleanup/`
**Purpose:** Comprehensive system cleanup with advanced features

**Parameters:**
- `-n, --dry-run` - Preview mode
- `-y, --yes` - Skip confirmations
- `-v, --verbose` - Detailed output
- `-q, --quick` - Basic cleanup only
- `--version` - Show version info

**Prerequisites:**
- macOS 10.12 or later
- bash shell
- Administrator privileges for some operations

**Dependencies:** Standard UNIX utilities
**Usage:** `./maincleanup.sh --dry-run --verbose`

---

## macOS Logging Framework

### 14. example_usage.sh
**Location:** `/users/jonathan/files/10scripts/mac/logging/`
**Purpose:** Demonstrates logging framework usage

**Parameters:**
- Environment variable: `LOG_LEVEL` (DEBUG, INFO, WARN, ERROR)

**Prerequisites:**
- bash shell
- logging_framework.sh in same directory

**Dependencies:** logging_framework.sh
**Usage:** `LOG_LEVEL=DEBUG ./example_usage.sh`

---

### 15. logging_framework.sh
**Location:** `/users/jonathan/files/10scripts/mac/logging/`
**Purpose:** Comprehensive logging and error handling framework

**Parameters:**
- Source this file: `source logging_framework.sh`
- Environment variables: `LOG_LEVEL`, `LOG_FILE`

**Prerequisites:**
- bash shell
- UNIX utilities (date, mktemp)

**Dependencies:** None (standalone framework)
**Usage:** `source logging_framework.sh` then use log_info, log_error functions

---

### 16. test_signal_handling.sh
**Location:** `/users/jonathan/files/10scripts/mac/logging/`
**Purpose:** Tests signal handling and cleanup functionality

**Parameters:**
- Sourced logging framework with DEBUG level

**Prerequisites:**
- bash shell
- logging_framework.sh

**Dependencies:** logging_framework.sh
**Usage:** `./test_signal_handling.sh` (press Ctrl+C to test)

---

## Office/Exchange Scripts

### 17. permissionscheck.ps1
**Location:** `/users/jonathan/files/10scripts/office/calendars/permissions/`
**Purpose:** Audits calendar permissions for a specific user across all mailboxes

**Parameters:**
- Interactive prompt for target user email
- Output CSV path: `CalendarPermissionsReport.csv`

**Prerequisites:**
- PowerShell module: ExchangeOnlineManagement
- Connection: `Connect-ExchangeOnline`

**Dependencies:** Exchange Online Management
**Usage:** Run script and provide target user email when prompted

---

### 18. matchdistlists.ps1 (office/distlist/)
**Location:** `/users/jonathan/files/10scripts/office/distlist/`
**Purpose:** Copies distribution list memberships between users

**Parameters:**
- `UserA` (Required) - Source user UPN
- `UserB` (Required) - Target user UPN

**Prerequisites:**
- PowerShell modules: Microsoft.Graph, ExchangeOnlineManagement
- Connections: `Connect-MgGraph`, `Connect-ExchangeOnline`
- Graph permissions: Group.ReadWrite.All, User.Read.All

**Dependencies:** Graph and Exchange modules
**Usage:** `./matchdistlists.ps1 -UserA alice@domain.com -UserB bob@domain.com`

---

### 19. galexport.ps1
**Location:** `/users/jonathan/files/10scripts/office/gal/`
**Purpose:** Exports all address lists to CSV

**Parameters:** None (hardcoded output to `~/all-addresslists.csv`)

**Prerequisites:**
- Exchange Online connection
- PowerShell module: ExchangeOnlineManagement

**Dependencies:** Exchange Online Management
**Usage:** `./galexport.ps1`

---

### 20. galusers.ps1
**Location:** `/users/jonathan/files/10scripts/office/gal/`
**Purpose:** Exports Global Address List users to CSV

**Parameters:** None (hardcoded output to `~/gal-emails.csv`)

**Prerequisites:**
- Exchange Online connection
- PowerShell module: ExchangeOnlineManagement

**Dependencies:** Exchange Online Management
**Usage:** `./galusers.ps1`

---

### Group Management Scripts (office/group/)

#### 21. Connect-Services.ps1
**Purpose:** Authenticates to Microsoft Graph and Exchange Online
**Dependencies:** ServiceConnectionModule.ps1
**Usage:** `./Connect-Services.ps1`

#### 22. ExampleUsage.ps1
**Purpose:** Demonstrates ServiceConnectionModule usage patterns
**Dependencies:** ServiceConnectionModule.ps1
**Usage:** `./ExampleUsage.ps1`

#### 23. ServiceConnectionModule.ps1
**Purpose:** Reusable connection module for Graph and Exchange
**Functions:** `Connect-ToMicrosoftGraph`, `Connect-ToExchangeOnline`, `Initialize-Connections`
**Usage:** `. .\ServiceConnectionModule.ps1`

#### 24. matchdistlists.ps1 (office/group/)
**Purpose:** Enhanced group membership copying with validation
**Parameters:** Same as distlist version but with enhanced error handling
**Prerequisites:** Comprehensive permission and module validation
**Usage:** Enhanced version with better error handling

---

### 25. setmailboxarchive.ps1
**Location:** `/users/jonathan/files/10scripts/office/mailarchive/`
**Purpose:** Configures mailbox archive policies with custom retention

**Parameters:**
- Interactive mode selection (existing vs. new retention tags)
- Custom retention days for new tags
- Comma-separated list of mailbox identities

**Prerequisites:**
- PowerShell module: ExchangeOnlineManagement
- Connection: `Connect-ExchangeOnline`
- Exchange admin permissions

**Dependencies:** Exchange Online Management
**Usage:** Run script and follow interactive prompts for policy configuration

---

### 26. New-M365Onboarding.ps1
**Location:** `/users/jonathan/files/10scripts/office/onboarding/`
**Purpose:** Automated Microsoft 365 user onboarding template

**Parameter Sets:**
- **SingleUser:** Direct parameter input
- **Interactive:** Prompted input with tenant data
- **BatchMode:** CSV file processing

**Key Parameters:**
- `UserPrincipalName`, `DisplayName`, `FirstName`, `LastName` (Required for SingleUser)
- `Department`, `JobTitle`, `Manager` (Optional)
- `DefaultLicenseSku` (Default: "ENTERPRISEPACK")
- `SecurityGroups`, `DistributionGroups` (Arrays)
- `InputCsv` (For batch mode)

**Prerequisites:**
- PowerShell modules: ExchangeOnlineManagement, Microsoft.Graph
- Connections: `Connect-MgGraph`, `Connect-ExchangeOnline`
- Graph permissions: User.ReadWrite.All, Group.ReadWrite.All, Directory.ReadWrite.All

**Dependencies:** Graph and Exchange modules
**Usage:** 
- Single: `./New-M365Onboarding.ps1 -UserPrincipalName user@domain.com -DisplayName "John Doe" -FirstName John -LastName Doe`
- Interactive: `./New-M365Onboarding.ps1 -Interactive`
- Batch: `./New-M365Onboarding.ps1 -InputCsv users.csv`

---

### 27. report.ps1
**Location:** `/users/jonathan/files/10scripts/office/sharepoint/`
**Purpose:** Exports SharePoint folder permissions for a specific user

**Parameters:**
- `Sites` (Required) - Array of SharePoint site URLs
- `User` (Required) - User Principal Name to check
- `OutputFile` (Optional) - CSV output path with auto-naming

**Prerequisites:**
- PowerShell module: PnP.PowerShell
- SharePoint permissions

**Dependencies:** PnP.PowerShell module
**Usage:** `./report.ps1 -Sites https://contoso.sharepoint.com/sites/TeamSite -User alice@contoso.com`

---

## Common Prerequisites Summary

### PowerShell Modules Required:
- **Microsoft.Graph** (Multiple components: Users, Groups, DeviceManagement)
- **ExchangeOnlineManagement**
- **PnP.PowerShell** (SharePoint operations)

### Connection Commands:
- **Microsoft Graph:** `Connect-MgGraph` with appropriate scopes
- **Exchange Online:** `Connect-ExchangeOnline`
- **SharePoint:** `Connect-PnPOnline`

### macOS Shell Requirements:
- **zsh** (default on macOS Catalina+)
- **bash** (for logging framework)
- Standard UNIX utilities (find, du, rm, etc.)

---

## Security Considerations

### Graph API Permissions:
Most scripts require elevated permissions including:
- User.Read.All / User.ReadWrite.All
- Group.ReadWrite.All
- DeviceManagementManagedDevices.Read.All
- Directory.ReadWrite.All

### Exchange Permissions:
- Exchange administrator role
- Mailbox access permissions
- Distribution group management rights

### macOS Scripts:
- File system access to user directories
- Potential administrator privileges for system cleanup

---

## Recommendations

1. **Test all scripts in non-production environments first**
2. **Use dry-run modes where available**
3. **Ensure proper backup procedures before cleanup operations**
4. **Validate Graph API permissions before script execution**
5. **Monitor script execution logs for troubleshooting**
6. **Keep PowerShell modules updated**
7. **Use least-privilege access principles**

---

*End of Analysis Report*
