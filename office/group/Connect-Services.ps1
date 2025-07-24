# Connect-Services.ps1
# Script to authenticate to Microsoft Graph and Exchange Online

Write-Host "Starting authentication to Microsoft Graph and Exchange Online..." -ForegroundColor Green

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

# Main execution
$mgGraphSuccess = Connect-ToMicrosoftGraph
$exchangeSuccess = Connect-ToExchangeOnline

# Summary
Write-Host "`nConnection Summary:" -ForegroundColor Magenta
Write-Host "Microsoft Graph: $(if ($mgGraphSuccess) { 'Connected' } else { 'Failed' })" -ForegroundColor $(if ($mgGraphSuccess) { 'Green' } else { 'Red' })
Write-Host "Exchange Online: $(if ($exchangeSuccess) { 'Connected' } else { 'Failed' })" -ForegroundColor $(if ($exchangeSuccess) { 'Green' } else { 'Red' })

if ($mgGraphSuccess -and $exchangeSuccess) {
    Write-Host "`nAll services connected successfully! You can now proceed with your operations." -ForegroundColor Green
} elseif ($mgGraphSuccess -or $exchangeSuccess) {
    Write-Host "`nPartial success. Some services are connected. Please resolve the failed connections before proceeding." -ForegroundColor Yellow
} else {
    Write-Host "`nAll connections failed. Please resolve the issues and try again." -ForegroundColor Red
}

# Return status for script automation
return @{
    MicrosoftGraph = $mgGraphSuccess
    ExchangeOnline = $exchangeSuccess
    AllConnected = ($mgGraphSuccess -and $exchangeSuccess)
}
