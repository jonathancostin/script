# Authentication Module for Microsoft 365 Offboarding Script v2.1
# This module handles Microsoft Graph and Exchange Online authentication

function Connect-M365Services {
    [CmdletBinding()]
    param(
        [string]$TenantId,
        [string]$ClientId,
        [string]$CertificateThumbprint,
        [switch]$Interactive
    )
    
    # Module availability checks and installations
    Test-RequiredModules
    
    # Disconnect existing sessions
    Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
    Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue
    
    Write-Host "Connecting to Microsoft 365 services..." -ForegroundColor Cyan
    
    if ($Interactive -or ([string]::IsNullOrEmpty($TenantId) -or [string]::IsNullOrEmpty($ClientId))) {
        Connect-InteractiveAuth
    } else {
        Connect-CertificateAuth -TenantId $TenantId -ClientId $ClientId -CertificateThumbprint $CertificateThumbprint
    }
}

function Test-RequiredModules {
    $requiredModules = @(
        @{Name = "Microsoft.Graph"; DisplayName = "Microsoft Graph"},
        @{Name = "ExchangeOnlineManagement"; DisplayName = "Exchange Online"}
    )
    
    foreach ($module in $requiredModules) {
        if (-not (Get-Module -Name $module.Name -ListAvailable)) {
            Write-Warning "The $($module.DisplayName) module is not installed."
            $install = Read-Host "Install $($module.DisplayName) module? [Y/N]"
            if ($install -match "[yY]") {
                Install-Module -Name $module.Name -Scope CurrentUser -AllowClobber
                Write-Host "$($module.DisplayName) module installed successfully." -ForegroundColor Green
            } else {
                throw "The $($module.DisplayName) module is required to run this script."
            }
        }
    }
}

function Connect-InteractiveAuth {
    $requiredScopes = @(
        "Directory.ReadWrite.All",
        "AppRoleAssignment.ReadWrite.All",
        "User.EnableDisableAccount.All",
        "Directory.AccessAsUser.All",
        "RoleManagement.ReadWrite.Directory"
    )
    
    Connect-MgGraph -Scopes $requiredScopes -ErrorAction Stop
    Connect-ExchangeOnline -UserPrincipalName (Get-MgContext).Account -ShowBanner:$false
}

function Connect-CertificateAuth {
    param($TenantId, $ClientId, $CertificateThumbprint)
    
    Connect-MgGraph -TenantId $TenantId -ClientId $ClientId -CertificateThumbprint $CertificateThumbprint -ErrorAction Stop
    
    # Validate permissions
    $scopes = (Get-MgContext).Scopes
    $requiredPermissions = @("Directory.ReadWrite.All", "AppRoleAssignment.ReadWrite.All", "User.EnableDisableAccount.All", "RoleManagement.ReadWrite.Directory")
    
    foreach ($permission in $requiredPermissions) {
        if ($scopes -notcontains $permission) {
            throw "Missing required permission: $permission"
        }
    }
    
    $organization = (Get-MgDomain | Where-Object {$_.IsInitial}).Id
    Connect-ExchangeOnline -AppId $ClientId -CertificateThumbprint $CertificateThumbprint -Organization $organization -ShowBanner:$false
}

function Disconnect-M365Services {
    Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
    Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue
}

Export-ModuleMember -Function Connect-M365Services, Disconnect-M365Services
