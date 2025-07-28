# ExampleUsage.ps1
# Example script demonstrating how to import and use the ServiceConnectionModule

# Import the Service Connection Module
. $PSScriptRoot\ServiceConnectionModule.ps1

Write-Host "=== Service Connection Module Usage Example ===" -ForegroundColor Cyan

# Example 1: Initialize all connections at once
Write-Host "`nExample 1: Using Initialize-Connections function" -ForegroundColor Blue
$connectionStatus = Initialize-Connections

if ($connectionStatus.AllConnected) {
    Write-Host "✓ All services connected - proceeding with operations" -ForegroundColor Green
    
    # Example operations you could perform here:
    # Get-MgUser -Top 5 | Select-Object DisplayName, UserPrincipalName
    # Get-Mailbox -ResultSize 5 | Select-Object DisplayName, PrimarySmtpAddress
    
} elseif ($connectionStatus.PartialConnection) {
    Write-Host "⚠ Partial connection - limited operations available" -ForegroundColor Yellow
    
    if ($connectionStatus.MicrosoftGraph) {
        Write-Host "Microsoft Graph operations are available" -ForegroundColor Green
    }
    
    if ($connectionStatus.ExchangeOnline) {
        Write-Host "Exchange Online operations are available" -ForegroundColor Green
    }
} else {
    Write-Host "❌ No connections established - cannot proceed" -ForegroundColor Red
    exit 1
}

# Example 2: Using individual connection functions
Write-Host "`nExample 2: Using individual connection functions" -ForegroundColor Blue

# Connect to Microsoft Graph only
Write-Host "Connecting to Microsoft Graph only..." -ForegroundColor Yellow
$mgResult = Connect-ToMicrosoftGraph

if ($mgResult) {
    Write-Host "Microsoft Graph connection successful - can perform user/group operations" -ForegroundColor Green
} else {
    Write-Host "Microsoft Graph connection failed" -ForegroundColor Red
}

# Connect to Exchange Online only
Write-Host "Connecting to Exchange Online only..." -ForegroundColor Yellow
$exoResult = Connect-ToExchangeOnline

if ($exoResult) {
    Write-Host "Exchange Online connection successful - can perform mailbox operations" -ForegroundColor Green
} else {
    Write-Host "Exchange Online connection failed" -ForegroundColor Red
}

# Example 3: Error handling in your scripts
Write-Host "`nExample 3: Implementing error handling" -ForegroundColor Blue

try {
    $status = Initialize-Connections
    
    if (-not $status.AllConnected) {
        throw "Required services are not connected"
    }
    
    Write-Host "Proceeding with script operations..." -ForegroundColor Green
    # Your main script logic here
    
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    Write-Host "Please resolve connection issues and try again." -ForegroundColor Yellow
    exit 1
}

Write-Host "`n=== Example completed ===" -ForegroundColor Cyan
