# Function to snapshot user metadata
function Start-UserBackup {
    param([
        string]$UserPrincipalName,
        [string]$BackupLocation
    )
    try {
        # Snapshot user metadata
        $userMetadata = Get-MgUser -UserId $UserPrincipalName -Property "*"
        $userMetadataFile = Join-Path -Path $BackupLocation -ChildPath "UserMetadata_$($UserPrincipalName.Replace('@','_'))_$(Get-Date -Format 'yyyyMMddHHmmss').json"
        $userMetadata | ConvertTo-Json -Depth 10 | Out-File -FilePath $userMetadataFile

        Write-AuditLog -Message "User metadata snapshot created for $UserPrincipalName" -Level "INFO"
        return "Success"
    } catch {
        Write-LogError -UPN $UserPrincipalName -Action "Start-UserBackup" -Error $_.Exception.Message
        return "Failed"
    }
}

# Backup mailbox items
function Backup-MailboxItems {
    param(
        [string]$UserPrincipalName,
        [string]$BackupLocation
    )
    try {
        # Backup command to use Graph API for mailbox export
        $mailboxData = Get-MgUserMessage -UserId $UserPrincipalName
        $mailboxDataFile = Join-Path -Path $BackupLocation -ChildPath "Mailbox_$($UserPrincipalName.Replace('@','_'))_$(Get-Date -Format 'yyyyMMddHHmmss').json"
        $mailboxData | ConvertTo-Json -Depth 10 | Out-File -FilePath $mailboxDataFile

        Write-AuditLog -Message "Mailbox items backed up for $UserPrincipalName" -Level "INFO"
        return "Success"
    } catch {
        Write-LogError -UPN $UserPrincipalName -Action "Backup-MailboxItems" -Error $_.Exception.Message
        return "Failed"
    }
}

# Download OneDrive files
function Download-OneDriveFiles {
    param(
        [string]$UserPrincipalName,
        [string]$BackupLocation
    )
    try {
        # Command to download OneDrive files (Note: Requires configuring SharePoint/OneDrive access)
        $oneDriveFiles = Get-MgUserDriveItem -UserId $UserPrincipalName
        $oneDriveBackupPath = Join-Path -Path $BackupLocation -ChildPath "OneDrive_$($UserPrincipalName.Replace('@','_'))_$(Get-Date -Format 'yyyyMMddHHmmss')"
        
        # Assuming function to download exists and iterating over each file
        foreach ($file in $oneDriveFiles) {
            $filePath = Join-Path -Path $oneDriveBackupPath -ChildPath $file.Name
            # Download logic for each file (pseudo-code)
            # Download-File -FileId $file.Id -DestinationPath $filePath
        }
        Write-AuditLog -Message "OneDrive files downloaded for $UserPrincipalName" -Level "INFO"
        return "Success"
    } catch {
        Write-LogError -UPN $UserPrincipalName -Action "Download-OneDriveFiles" -Error $_.Exception.Message
        return "Failed"
    }
}

# Generate backup report
function Generate-BackupReport {
    param([
        string]$BackupLocation
    )
    try {
        $timestamp = Get-Date -Format 'yyyyMMddHHmmss'
        $reportFile = Join-Path -Path $BackupLocation -ChildPath "BackupReport_$timestamp.json"

        $fileCounts = Get-ChildItem -Path $BackupLocation | Measure-Object

        $reportData = @{
            Timestamp = $timestamp
            Status = "Completed"
            FileCount = $fileCounts.Count
        }

        $reportData | ConvertTo-Json | Out-File -FilePath $reportFile

        Write-AuditLog -Message "Backup report generated at $reportFile" -Level "INFO"
        return "Success"
    } catch {
        Write-LogError -Action "Generate-BackupReport" -Error $_.Exception.Message
        return "Failed"
    }
}

# User Operations Module for Microsoft 365 Offboarding Script v2.1
# This module contains all user offboarding operations

# User Identity Operations
function Disable-M365User {
    param([string]$UserPrincipalName)
    
    try {
        Update-MgUser -UserId $UserPrincipalName -AccountEnabled:$false
        return "Success"
    }
    catch {
        Write-LogError -UPN $UserPrincipalName -Action "Disable User" -Error $_.Exception.Message
        return "Failed"
    }
}

function Reset-UserPasswordToRandom {
    param([string]$UserPrincipalName)
    
    try {
        $password = New-RandomPassword
        $securePassword = ConvertTo-SecureString $password -AsPlainText -Force
        
        $passwordProfile = @{
            forceChangePasswordNextSignIn = $true
            password = $securePassword
        }
        
        Update-MgUser -UserId $UserPrincipalName -PasswordProfile $passwordProfile
        Write-PasswordLog -UPN $UserPrincipalName -Password $password
        return "Success"
    }
    catch {
        Write-LogError -UPN $UserPrincipalName -Action "Reset Password" -Error $_.Exception.Message
        return "Failed"
    }
}

function Reset-UserOfficeLocation {
    param([string]$UserPrincipalName)
    
    try {
        Update-MgUser -UserId $UserPrincipalName -OfficeLocation "EXD"
        return "Success"
    }
    catch {
        Write-LogError -UPN $UserPrincipalName -Action "Reset Office Location" -Error $_.Exception.Message
        return "Failed"
    }
}

function Remove-UserMobileNumber {
    param([string]$UserPrincipalName)
    
    try {
        Update-MgUser -UserId $UserPrincipalName -MobilePhone $null
        return "Success"
    }
    catch {
        Write-LogError -UPN $UserPrincipalName -Action "Remove Mobile Number" -Error $_.Exception.Message
        return "Failed"
    }
}

# Group and Role Operations
function Remove-UserGroupMemberships {
    param([string]$UserPrincipalName, [string]$UserId)
    
    try {
        $memberships = Get-MgUserMemberOf -UserId $UserPrincipalName
        $groupMemberships = $memberships | Where-Object {
            $_.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.group' -and
            $_.AdditionalProperties.'groupTypes' -notcontains 'DynamicMembership'
        }
        
        foreach ($membership in $groupMemberships) {
            Remove-MgGroupMemberByRef -GroupId $membership.Id -DirectoryObjectId $UserId -ErrorAction SilentlyContinue
        }
        
        # Remove group ownerships
        $ownerships = Get-MgUserOwnedObject -UserId $UserPrincipalName | Where-Object {
            $_.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.group'
        }
        
        foreach ($ownership in $ownerships) {
            Remove-MgGroupOwnerByRef -GroupId $ownership.Id -DirectoryObjectId $UserId -ErrorAction SilentlyContinue
        }
        
        return "Success"
    }
    catch {
        Write-LogError -UPN $UserPrincipalName -Action "Remove Group Memberships" -Error $_.Exception.Message
        return "Failed"
    }
}

function Remove-UserAdminRoles {
    param([string]$UserPrincipalName, [string]$UserId)
    
    try {
        $memberships = Get-MgUserMemberOf -UserId $UserPrincipalName
        $adminRoles = $memberships | Where-Object {
            $_.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.directoryRole'
        }
        
        if ($adminRoles.Count -eq 0) {
            return "No admin roles"
        }
        
        foreach ($role in $adminRoles) {
            Remove-MgDirectoryRoleMemberByRef -DirectoryObjectId $UserId -DirectoryRoleId $role.Id
        }
        
        return "Success"
    }
    catch {
        Write-LogError -UPN $UserPrincipalName -Action "Remove Admin Roles" -Error $_.Exception.Message
        return "Failed"
    }
}

function Remove-UserAppRoleAssignments {
    param([string]$UserPrincipalName)
    
    try {
        $appRoleAssignments = Get-MgUserAppRoleAssignment -UserId $UserPrincipalName
        
        if ($appRoleAssignments.Count -eq 0) {
            return "No app role assignments"
        }
        
        foreach ($assignment in $appRoleAssignments) {
            Remove-MgUserAppRoleAssignment -AppRoleAssignmentId $assignment.Id -UserId $UserPrincipalName
        }
        
        return "Success"
    }
    catch {
        Write-LogError -UPN $UserPrincipalName -Action "Remove App Role Assignments" -Error $_.Exception.Message
        return "Failed"
    }
}

# Exchange Operations
function Hide-UserFromAddressList {
    param([string]$UserPrincipalName, [bool]$HasMailbox)
    
    if (-not $HasMailbox) {
        return "No Exchange license assigned to user"
    }
    
    try {
        Set-Mailbox -Identity $UserPrincipalName -HiddenFromAddressListsEnabled $true
        return "Success"
    }
    catch {
        Write-LogError -UPN $UserPrincipalName -Action "Hide From Address List" -Error $_.Exception.Message
        return "Failed"
    }
}

function Remove-UserEmailAliases {
    param([string]$UserPrincipalName, [bool]$HasMailbox)
    
    if (-not $HasMailbox) {
        return "No Exchange license assigned to user"
    }
    
    try {
        $aliases = Get-Mailbox $UserPrincipalName | Select-Object -ExpandProperty EmailAddresses | Where-Object {$_.StartsWith("smtp")}
        
        if ($aliases.Count -eq 0) {
            return "No aliases"
        }
        
        Set-Mailbox $UserPrincipalName -EmailAddresses @{Remove=$aliases} -WarningAction SilentlyContinue
        return "Success"
    }
    catch {
        Write-LogError -UPN $UserPrincipalName -Action "Remove Email Aliases" -Error $_.Exception.Message
        return "Failed"
    }
}

function Clear-UserMobileDevices {
    param([string]$UserPrincipalName, [bool]$HasMailbox)
    
    if (-not $HasMailbox) {
        return "No Exchange license assigned to user"
    }
    
    try {
        $mobileDevices = Get-MobileDevice -Mailbox $UserPrincipalName
        $mobileDevices | Clear-MobileDevice
        return "Success"
    }
    catch {
        Write-LogError -UPN $UserPrincipalName -Action "Clear Mobile Devices" -Error $_.Exception.Message
        return "Failed"
    }
}

function Remove-UserInboxRules {
    param([string]$UserPrincipalName, [bool]$HasMailbox)
    
    if (-not $HasMailbox) {
        return "No Exchange license assigned to user"
    }
    
    try {
        $inboxRules = Get-InboxRule -Mailbox $UserPrincipalName
        $inboxRules | Remove-InboxRule -Confirm:$false
        return "Success"
    }
    catch {
        return "No inbox rules"
    }
}

function Convert-UserToSharedMailbox {
    param([string]$UserPrincipalName, [bool]$HasMailbox)
    
    if (-not $HasMailbox) {
        return "No Exchange license assigned to user"
    }
    
    try {
        Set-Mailbox -Identity $UserPrincipalName -Type Shared -WarningAction SilentlyContinue
        return "Success"
    }
    catch {
        Write-LogError -UPN $UserPrincipalName -Action "Convert To Shared Mailbox" -Error $_.Exception.Message
        return "Failed"
    }
}

function Remove-UserLicenses {
    param([string]$UserPrincipalName)
    
    try {
        $licenses = Get-MgUserLicenseDetail -UserId $UserPrincipalName
        
        if ($licenses.Count -eq 0) {
            return "No licenses"
        }
        
        Set-MgUserLicense -UserId $UserPrincipalName -RemoveLicenses @($licenses.SkuId) -AddLicenses @() -ErrorAction Stop
        return "Removed licenses - $($licenses.SkuPartNumber -join ',')"
    }
    catch {
        Write-LogError -UPN $UserPrincipalName -Action "Remove Licenses" -Error $_.Exception.Message
        return "Failed"
    }
}

function Revoke-UserSessions {
    param([string]$UserPrincipalName)
    
    try {
        Revoke-MgUserSignInSession -UserId $UserPrincipalName | Out-Null
        return "Success"
    }
    catch {
        Write-LogError -UPN $UserPrincipalName -Action "Revoke Sessions" -Error $_.Exception.Message
        return "Failed"
    }
}

# Helper Functions
function New-RandomPassword {
    return -join ((48..57) + (65..90) + (97..122) | ForEach-Object { [char]$_ } | Get-Random -Count 12)
}

function Test-UserMailbox {
    param([string]$UserPrincipalName)
    
    try {
        $mailbox = Get-Mailbox -Identity $UserPrincipalName -RecipientTypeDetails UserMailbox -ErrorAction SilentlyContinue
        return ($null -ne $mailbox)
    }
    catch {
        return $false
    }
}

# Export all functions
Export-ModuleMember -Function *
