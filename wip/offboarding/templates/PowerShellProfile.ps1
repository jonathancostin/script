# PowerShell Profile Template for Microsoft 365 Offboarding Script v2.1
# This profile template can be used to automatically load required modules

# Set execution policy for current user (if needed)
# Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Import required modules for Microsoft 365 operations
$ModulePath = Split-Path $PSScriptRoot -Parent
$ModulesPath = Join-Path $ModulePath "modules"

# Auto-load custom modules
$CustomModules = @(
    "AuthenticationModule",
    "UserOperationsModule", 
    "LoggingModule"
)

foreach ($Module in $CustomModules) {
    $ModuleFile = Join-Path $ModulesPath "$Module.psm1"
    if (Test-Path $ModuleFile) {
        Import-Module $ModuleFile -Force -DisableNameChecking
        Write-Host "Loaded module: $Module" -ForegroundColor Green
    }
}

# Verify Microsoft Graph and Exchange Online modules
$RequiredModules = @("Microsoft.Graph", "ExchangeOnlineManagement")
foreach ($Module in $RequiredModules) {
    if (Get-Module -Name $Module -ListAvailable) {
        Write-Host "Microsoft module available: $Module" -ForegroundColor Green
    } else {
        Write-Warning "Microsoft module missing: $Module - Run Install-Module $Module"
    }
}

# Set default parameters for enhanced security
$PSDefaultParameterValues = @{
    'Connect-MgGraph:Scopes' = @(
        'Directory.ReadWrite.All',
        'AppRoleAssignment.ReadWrite.All',
        'User.EnableDisableAccount.All',
        'RoleManagement.ReadWrite.Directory'
    )
    'Connect-ExchangeOnline:ShowBanner' = $false
}

Write-Host "Microsoft 365 Offboarding Environment Ready!" -ForegroundColor Cyan
