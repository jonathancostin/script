# Microsoft 365 User Offboarding Automation Script

A comprehensive PowerShell solution for automating Microsoft 365 user offboarding processes with enhanced security, reliability, and operational features.

## 🚀 Features

### Core Offboarding Operations
1. **Disable User Account** - Prevents user login
2. **Reset Password** - Sets random password with forced change on next login
3. **Reset Office Location** - Updates office location to "EXD" (Exited)
4. **Remove Mobile Number** - Clears mobile phone information
5. **Remove Group Memberships** - Removes user from all groups and ownership roles
6. **Remove Admin Roles** - Revokes all administrative privileges
7. **Remove App Role Assignments** - Cleans up application permissions
8. **Hide from Address List** - Hides user from Global Address List
9. **Remove Email Aliases** - Removes secondary email addresses
10. **Wipe Mobile Devices** - Initiates remote wipe of mobile devices
11. **Delete Inbox Rules** - Removes all mailbox rules
12. **Convert to Shared Mailbox** - Converts user mailbox to shared
13. **Remove Licenses** - Revokes all Microsoft 365 licenses
14. **Sign Out All Sessions** - Terminates all active user sessions

### Enhanced Features (v2.1+)
- ✅ **User Data Backup** - Automated backup of critical user data
- ✅ **OneDrive Management** - Comprehensive OneDrive data handling
- ✅ **Enhanced Security** - Improved password and MFA management
- ✅ **Teams Cleanup** - Microsoft Teams data and membership cleanup
- ✅ **Calendar Delegation** - Automated calendar delegation management
- ✅ **Retry Logic** - Robust error handling with automatic retries
- ✅ **Configuration Support** - JSON-based configuration management
- ✅ **Structured Logging** - Enhanced logging with multiple formats
- ✅ **Pre-flight Checks** - System validation before execution
- ✅ **Rollback Capabilities** - Ability to reverse offboarding actions

## 📋 Prerequisites

### Required PowerShell Modules
- **Microsoft.Graph** (Auto-installed if missing)
- **ExchangeOnlineManagement** (Auto-installed if missing)
- **Microsoft.Graph.Teams** (For Teams cleanup)
- **SharePointPnPPowerShellOnline** (For OneDrive management)

### Required Permissions
- **Directory.ReadWrite.All**
- **AppRoleAssignment.ReadWrite.All**
- **User.EnableDisableAccount.All**
- **RoleManagement.ReadWrite.Directory**
- **Directory.AccessAsUser.All**
- **Sites.FullControl.All** (For OneDrive backup)
- **Group.ReadWrite.All** (For Teams cleanup)

### Authentication Options
1. **Interactive Authentication** (Default)
2. **Certificate-based Authentication** (Recommended for automation)
3. **Service Principal with Client Secret**

## 🛠️ Installation

1. Clone or download the script files
2. Ensure PowerShell execution policy allows script execution:
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```
3. Install required modules (handled automatically by script)

## 📖 Usage

### Basic Usage
```powershell
# Interactive mode - script will prompt for UPN
.\offboards.ps1

# Single user offboarding
.\offboards.ps1 -UPNs "user@domain.com"

# Multiple users
.\offboards.ps1 -UPNs "user1@domain.com,user2@domain.com"

# CSV file input
.\offboards.ps1 -CSVFilePath "C:\Users\users.csv"
```

### Advanced Usage with Certificate Authentication
```powershell
.\offboards.ps1 -TenantId "your-tenant-id" -ClientId "your-app-id" -CertificateThumbprint "cert-thumbprint" -UPNs "user@domain.com"
```

### Configuration File Usage
```powershell
# Use custom configuration
.\offboards.ps1 -ConfigPath "C:\Config\offboarding-config.json" -UPNs "user@domain.com"
```

## ⚙️ Configuration

### Configuration File Structure (offboarding-config.json)
```json
{
  "backup": {
    "enabled": true,
    "backupPath": "C:\\UserBackups",
    "includeOneDrive": true,
    "includeEmail": false,
    "retentionDays": 365
  },
  "onedrive": {
    "transferOwnership": true,
    "newOwner": "admin@domain.com",
    "downloadData": true,
    "deleteAfterTransfer": false
  },
  "security": {
    "passwordComplexity": "high",
    "disableMFA": true,
    "revokeTokens": true,
    "blockSignIn": true
  },
  "teams": {
    "cleanupEnabled": true,
    "transferOwnership": true,
    "archiveTeams": true,
    "removeFromAllTeams": true
  },
  "calendar": {
    "delegateEnabled": true,
    "defaultDelegate": "manager@domain.com",
    "copyCalendar": true
  },
  "retry": {
    "maxAttempts": 3,
    "delaySeconds": 5,
    "exponentialBackoff": true
  },
  "logging": {
    "level": "INFO",
    "formats": ["json", "csv"],
    "archiveAfterDays": 90
  },
  "rollback": {
    "enabled": true,
    "createSnapshot": true,
    "retentionDays": 30
  }
}
```

### CSV Input Format
Create a CSV file with a single column named `UserPrincipalName`:
```csv
UserPrincipalName
user1@domain.com
user2@domain.com
user3@domain.com
```

## 📊 Output Files

The script generates several output files with timestamps:

### Standard Output Files
- **Status Report**: `M365UserOffBoarding_StatusFile_[timestamp].csv`
- **Password Log**: `PasswordLogFile_[timestamp].txt`
- **Invalid Users**: `InvalidUsersLogFile[timestamp].txt`
- **Error Log**: `ErrorsLogFile[timestamp].txt`

### Enhanced Output Files (v2.1+)
- **Backup Report**: `BackupReport_[timestamp].json`
- **OneDrive Transfer**: `OneDriveTransfer_[timestamp].csv`
- **Teams Cleanup**: `TeamsCleanup_[timestamp].json`
- **Rollback Data**: `RollbackData_[timestamp].json`
- **Audit Trail**: `AuditTrail_[timestamp].log`

## 🔧 Action Selection

When running the script, you can choose from these actions:

```
1.  Disable user
2.  Reset password to random
3.  Reset Office name
4.  Remove Mobile number
5.  Remove group memberships
6.  Remove admin roles
7.  Remove app role assignments
8.  Hide from address list
9.  Remove email alias
10. Wiping mobile device
11. Delete inbox rule
12. Convert to shared mailbox
13. Remove license
14. Sign-out from all sessions
15. All the above operations
16. Backup user data (Enhanced)
17. OneDrive management (Enhanced)
18. Teams cleanup (Enhanced)
19. Calendar delegation (Enhanced)
20. Full enhanced offboarding (Enhanced)
```

## 🚨 Pre-flight Checks

The enhanced script performs comprehensive pre-flight checks:

- ✅ PowerShell version compatibility
- ✅ Required modules availability
- ✅ Network connectivity to Microsoft services
- ✅ Authentication token validity
- ✅ Required permissions verification
- ✅ Backup storage availability
- ✅ Configuration file validation
- ✅ User account existence verification

## 🔄 Retry Logic

The script implements intelligent retry mechanisms:

- **Exponential Backoff**: Increases delay between retries
- **Configurable Attempts**: Set maximum retry attempts
- **Selective Retries**: Only retries transient failures
- **Circuit Breaker**: Prevents cascade failures

## 📝 Logging Levels

Configure logging verbosity:

- **ERROR**: Only errors and critical issues
- **WARN**: Warnings and above
- **INFO**: General information and above (Default)
- **DEBUG**: Detailed diagnostic information
- **TRACE**: Most verbose logging

## 🔙 Rollback Capabilities

### Available Rollback Operations
- Restore user account status
- Revert license assignments
- Restore group memberships
- Revert admin role assignments
- Restore mailbox settings
- Revert OneDrive permissions

### Rollback Usage
```powershell
# Perform rollback using snapshot
.\rollback.ps1 -SnapshotId "snapshot-uuid" -UPN "user@domain.com"

# List available snapshots
.\rollback.ps1 -ListSnapshots -UPN "user@domain.com"
```

## 🛡️ Security Considerations

- **Least Privilege**: Use service accounts with minimal required permissions
- **Certificate Authentication**: Recommended for production environments
- **Audit Logging**: All actions are logged for compliance
- **Data Encryption**: Sensitive data is encrypted at rest
- **Access Control**: Restrict script access to authorized personnel

## 🔍 Troubleshooting

### Common Issues

1. **Module Installation Failures**
   - Run PowerShell as Administrator
   - Check internet connectivity
   - Verify execution policy settings

2. **Authentication Errors**
   - Verify tenant ID and client ID
   - Check certificate installation
   - Confirm required permissions

3. **Backup Failures**
   - Verify backup path permissions
   - Check available disk space
   - Confirm OneDrive access

4. **OneDrive Transfer Issues**
   - Verify site collection admin rights
   - Check target user permissions
   - Confirm SharePoint Online connectivity

## 📚 Additional Resources

- [Microsoft Graph PowerShell SDK Documentation](https://docs.microsoft.com/en-us/graph/powershell/get-started)
- [Exchange Online PowerShell Documentation](https://docs.microsoft.com/en-us/powershell/exchange/exchange-online-powershell)
- [Azure AD App Registration Guide](https://docs.microsoft.com/en-us/azure/active-directory/develop/quickstart-register-app)

## 🆘 Support

For issues and support:
1. Check the error logs generated by the script
2. Review the troubleshooting section
3. Consult Microsoft documentation for specific API limitations
4. Contact your system administrator for permission-related issues

## 📜 License

This script is provided as-is for educational and operational purposes. Please review and test thoroughly before using in production environments.

## 🔄 Version History

- **v2.1** - Enhanced features: backup, OneDrive management, retry logic, structured logging
- **v2.0** - Original AdminDroid Community version
- **v1.x** - Legacy versions

---

**⚠️ Important**: Always test the script in a non-production environment first. Offboarding operations can be irreversible, so ensure you have proper backups and approval processes in place.
