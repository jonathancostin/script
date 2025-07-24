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
