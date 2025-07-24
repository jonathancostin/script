#Requires -Version 5.1

<#
.SYNOPSIS
    Copies group memberships from UserA to UserB.

.DESCRIPTION
    This script copies all distribution list and group memberships from a source user (UserA)
    to a target user (UserB) using Microsoft Graph and Exchange Online Management modules.
    The script will identify all groups that UserA is a member of and add UserB to those same groups.

.PARAMETER UserA
    UPN (User Principal Name) of the source user whose group memberships will be copied.
    This should be in the format: user@domain.com

.PARAMETER UserB
    UPN (User Principal Name) of the target user who will receive the group memberships.
    This should be in the format: user@domain.com

.EXAMPLE
    .\matchdistlists.ps1 -UserA alice@domain.com -UserB bob@domain.com
    
    Copies all group memberships from alice@domain.com to bob@domain.com

.EXAMPLE
    .\matchdistlists.ps1 -UserA "john.doe@contoso.com" -UserB "jane.smith@contoso.com"
    
    Copies all group memberships from john.doe@contoso.com to jane.smith@contoso.com

.NOTES
    Author: Generated Script
    Requires: Microsoft.Graph.Groups, ExchangeOnlineManagement modules
    Requires: Appropriate Graph API and Exchange Online permissions
    Requires: Group.Read.All and Group.ReadWrite.All permissions for Microsoft Graph
#>

param(
    [Parameter(Mandatory=$true, HelpMessage="UPN of the source user whose group memberships will be copied")]
    [ValidateNotNullOrEmpty()]
    [string]$UserA,
    
    [Parameter(Mandatory=$true, HelpMessage="UPN of the target user who will receive the group memberships")]
    [ValidateNotNullOrEmpty()]
    [string]$UserB
)

# Check if required modules are installed, install if missing
$requiredModules = @(
    'Microsoft.Graph.Groups',
    'ExchangeOnlineManagement'
)

Write-Host "Checking for required PowerShell modules..." -ForegroundColor Yellow

foreach ($module in $requiredModules) {
    if (Get-Module -ListAvailable -Name $module) {
        Write-Host "✓ Module '$module' is already installed" -ForegroundColor Green
        Import-Module $module -Force
    } else {
        Write-Host "⚠ Module '$module' not found. Installing..." -ForegroundColor Yellow
        try {
            Install-Module -Name $module -Scope CurrentUser -Force -AllowClobber
            Import-Module $module -Force
            Write-Host "✓ Module '$module' installed and imported successfully" -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to install module '$module': $($_.Exception.Message)"
            exit 1
        }
    }
}

# Function to check Graph API permissions
function Test-GraphPermissions {
    Write-Host "Checking Microsoft Graph permissions..." -ForegroundColor Yellow
    
    try {
        # Test connection to Microsoft Graph
        $context = Get-MgContext
        if ($null -eq $context) {
            Write-Host "⚠ Not connected to Microsoft Graph. Please run Connect-MgGraph first." -ForegroundColor Yellow
            return $false
        }
        
        Write-Host "✓ Connected to Microsoft Graph as: $($context.Account)" -ForegroundColor Green
        Write-Host "  Scopes: $($context.Scopes -join ', ')" -ForegroundColor Cyan
        
        # Check if we have the necessary permissions for Groups
        $requiredScopes = @('Group.Read.All', 'Group.ReadWrite.All')
        $hasRequiredScope = $false
        
        foreach ($scope in $requiredScopes) {
            if ($context.Scopes -contains $scope) {
                $hasRequiredScope = $true
                break
            }
        }
        
        if (-not $hasRequiredScope) {
            Write-Warning "Missing required Graph permissions. You need one of: $($requiredScopes -join ', ')"
            return $false
        }
        
        return $true
    }
    catch {
        Write-Warning "Error checking Graph permissions: $($_.Exception.Message)"
        return $false
    }
}

# Function to check Exchange Online permissions
function Test-ExchangeOnlinePermissions {
    Write-Host "Checking Exchange Online permissions..." -ForegroundColor Yellow
    
    try {
        # Test connection to Exchange Online
        $session = Get-PSSession | Where-Object { $_.ConfigurationName -eq "Microsoft.Exchange" -and $_.State -eq "Opened" }
        
        if ($null -eq $session) {
            Write-Host "⚠ Not connected to Exchange Online. Please run Connect-ExchangeOnline first." -ForegroundColor Yellow
            return $false
        }
        
        Write-Host "✓ Connected to Exchange Online" -ForegroundColor Green
        
        # Test if we can read distribution groups
        try {
            $null = Get-DistributionGroup -ResultSize 1 -ErrorAction Stop
            Write-Host "✓ Exchange Online permissions verified - can read distribution groups" -ForegroundColor Green
            return $true
        }
        catch {
            Write-Warning "Insufficient Exchange Online permissions to read distribution groups: $($_.Exception.Message)"
            return $false
        }
    }
    catch {
        Write-Warning "Error checking Exchange Online permissions: $($_.Exception.Message)"
        return $false
    }
}

# Main execution
Write-Host "=== Distribution List Matching Script ===" -ForegroundColor Cyan
Write-Host ""

# Check permissions
$graphOK = Test-GraphPermissions
$exchangeOK = Test-ExchangeOnlinePermissions

if (-not $graphOK -or -not $exchangeOK) {
    Write-Host ""
    Write-Host "Prerequisites not met. Please ensure you have:" -ForegroundColor Red
    Write-Host "1. Connected to Microsoft Graph with appropriate permissions (Group.Read.All or Group.ReadWrite.All)" -ForegroundColor Red
    Write-Host "2. Connected to Exchange Online with distribution group read permissions" -ForegroundColor Red
    Write-Host ""
    Write-Host "Example connection commands:" -ForegroundColor Yellow
    Write-Host "  Connect-MgGraph -Scopes 'Group.Read.All'" -ForegroundColor Cyan
    Write-Host "  Connect-ExchangeOnline" -ForegroundColor Cyan
    exit 1
}

Write-Host ""
Write-Host "✓ All prerequisites met. Ready to proceed with distribution list operations." -ForegroundColor Green
Write-Host ""

# TODO: Add your distribution list matching logic here
