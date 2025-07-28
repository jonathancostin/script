# Connect-Services.ps1
# Script to authenticate to Microsoft Graph and Exchange Online
# Uses the ServiceConnectionModule for reusable connection functions

# Import the Service Connection Module
. $PSScriptRoot\ServiceConnectionModule.ps1

Write-Host "Starting authentication to Microsoft Graph and Exchange Online..." -ForegroundColor Green

# Main execution - use the Initialize-Connections function
$connectionStatus = Initialize-Connections

# Return the connection status for script automation
return $connectionStatus
