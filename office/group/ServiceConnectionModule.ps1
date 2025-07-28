# ServiceConnectionModule.ps1
# Reusable module for connecting to Microsoft Graph and Exchange Online services
# This module can be imported into other scripts using: . .\ServiceConnectionModule.ps1

# Function to connect to Microsoft Graph
function Connect-ToMicrosoftGraph {
    Write-Host "Attempting to connect to Microsoft Graph..." -ForegroundColor Yellow
    
    try {
        # Check if already connected
        $context = Get-MgContext -ErrorAction SilentlyContinue
        if ($context) {
            Write-Host "Already connected to Microsoft Graph as: $($context.Account)" -ForegroundColor Green
            return $true
        }
        
        # Connect with required scopes
        Connect-MgGraph -Scopes "GroupMember.ReadWrite.All", "User.Read.All" -NoWelcome
        
        # Verify connection
        $context = Get-MgContext
        if ($context) {
            Write-Host "Successfully connected to Microsoft Graph as: $($context.Account)" -ForegroundColor Green
            Write-Host "Scopes: $($context.Scopes -join ', ')" -ForegroundColor Cyan
            return $true
        } else {
            throw "Connection verification failed"
        }
    }
    catch {
        Write-Error "Failed to connect to Microsoft Graph: $($_.Exception.Message)"
        Write-Host "Possible solutions:" -ForegroundColor Yellow
        Write-Host "- Ensure you have the Microsoft.Graph PowerShell module installed: Install-Module Microsoft.Graph" -ForegroundColor Yellow
        Write-Host "- Check your internet connection" -ForegroundColor Yellow
        Write-Host "- Verify you have appropriate permissions in your Azure AD tenant" -ForegroundColor Yellow
        return $false
    }
}

# Function to connect to Exchange Online
function Connect-ToExchangeOnline {
    Write-Host "Attempting to connect to Exchange Online..." -ForegroundColor Yellow
    
    try {
        # Check if already connected
        $session = Get-PSSession | Where-Object { $_.ConfigurationName -eq "Microsoft.Exchange" -and $_.State -eq "Opened" }
        if ($session) {
            Write-Host "Already connected to Exchange Online" -ForegroundColor Green
            return $true
        }
        
        # Connect to Exchange Online
        Connect-ExchangeOnline -ShowBanner:$false
        
        # Verify connection by running a simple command
        $null = Get-OrganizationConfig -ErrorAction Stop
        Write-Host "Successfully connected to Exchange Online" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "Failed to connect to Exchange Online: $($_.Exception.Message)"
        Write-Host "Possible solutions:" -ForegroundColor Yellow
        Write-Host "- Ensure you have the ExchangeOnlineManagement PowerShell module installed: Install-Module ExchangeOnlineManagement" -ForegroundColor Yellow
        Write-Host "- Check your internet connection" -ForegroundColor Yellow
        Write-Host "- Verify you have Exchange Online administrator permissions" -ForegroundColor Yellow
        Write-Host "- Try running: Connect-ExchangeOnline -UserPrincipalName your-email@domain.com" -ForegroundColor Yellow
        return $false
    }
}

# Main function to initialize connections to both services
function Initialize-Connections {
    <#
    .SYNOPSIS
    Initializes connections to Microsoft Graph and Exchange Online services.
    
    .DESCRIPTION
    This function attempts to connect to both Microsoft Graph and Exchange Online,
    providing detailed status information and troubleshooting guidance on failure.
    
    .EXAMPLE
    $status = Initialize-Connections
    if ($status.AllConnected) {
        Write-Host "Ready to proceed with operations"
    }
    
    .OUTPUTS
    Returns a hashtable with connection status:
    @{
        MicrosoftGraph = $true/$false
        ExchangeOnline = $true/$false
        AllConnected = $true/$false
    }
    #>
    
    Write-Host "Initializing connections to Microsoft services..." -ForegroundColor Blue
    Write-Host "This may require interactive authentication if not already logged in." -ForegroundColor Cyan
    
    # Initialize connection results
    $mgGraphSuccess = $false
    $exchangeSuccess = $false
    
    try {
        # Attempt Microsoft Graph connection
        Write-Host "`n--- Microsoft Graph Connection ---" -ForegroundColor Magenta
        $mgGraphSuccess = Connect-ToMicrosoftGraph
        
        # Attempt Exchange Online connection
        Write-Host "`n--- Exchange Online Connection ---" -ForegroundColor Magenta
        $exchangeSuccess = Connect-ToExchangeOnline
        
        # Provide comprehensive status summary
        Write-Host "`n=== CONNECTION SUMMARY ===" -ForegroundColor Magenta
        Write-Host "Microsoft Graph: $(if ($mgGraphSuccess) { 'Connected ✓' } else { 'Failed ✗' })" -ForegroundColor $(if ($mgGraphSuccess) { 'Green' } else { 'Red' })
        Write-Host "Exchange Online: $(if ($exchangeSuccess) { 'Connected ✓' } else { 'Failed ✗' })" -ForegroundColor $(if ($exchangeSuccess) { 'Green' } else { 'Red' })
        
        # Provide user guidance based on results
        if ($mgGraphSuccess -and $exchangeSuccess) {
            Write-Host "`n🎉 All services connected successfully!" -ForegroundColor Green
            Write-Host "You can now proceed with your Microsoft 365 operations." -ForegroundColor Green
        } elseif ($mgGraphSuccess -or $exchangeSuccess) {
            Write-Host "`n⚠️  Partial connection success." -ForegroundColor Yellow
            Write-Host "Some services are connected, but you may have limited functionality." -ForegroundColor Yellow
            Write-Host "Please resolve the failed connections before proceeding with operations that require both services." -ForegroundColor Yellow
        } else {
            Write-Host "`n❌ All connections failed." -ForegroundColor Red
            Write-Host "Please resolve the connection issues and try again." -ForegroundColor Red
            Write-Host "`nCommon troubleshooting steps:" -ForegroundColor Yellow
            Write-Host "1. Verify your internet connection" -ForegroundColor Yellow
            Write-Host "2. Check that required PowerShell modules are installed:" -ForegroundColor Yellow
            Write-Host "   - Install-Module Microsoft.Graph" -ForegroundColor Yellow
            Write-Host "   - Install-Module ExchangeOnlineManagement" -ForegroundColor Yellow
            Write-Host "3. Ensure you have appropriate permissions in your Microsoft 365 tenant" -ForegroundColor Yellow
            Write-Host "4. Try clearing cached credentials: Disconnect-MgGraph; Disconnect-ExchangeOnline" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Error "Unexpected error during connection initialization: $($_.Exception.Message)"
        Write-Host "Please try running the connection functions individually to identify the specific issue." -ForegroundColor Yellow
    }
    
    # Return detailed status object for automation
    $connectionStatus = @{
        MicrosoftGraph = $mgGraphSuccess
        ExchangeOnline = $exchangeSuccess
        AllConnected = ($mgGraphSuccess -and $exchangeSuccess)
        Timestamp = Get-Date
        PartialConnection = ($mgGraphSuccess -or $exchangeSuccess) -and -not ($mgGraphSuccess -and $exchangeSuccess)
    }
    
    return $connectionStatus
}

# Export functions for module usage
Export-ModuleMember -Function Connect-ToMicrosoftGraph, Connect-ToExchangeOnline, Initialize-Connections
