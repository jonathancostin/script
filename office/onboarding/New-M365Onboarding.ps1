#Requires -Modules ExchangeOnlineManagement, Microsoft.Graph

<#
.SYNOPSIS
    New-M365Onboarding.ps1 - Microsoft 365 User Onboarding Automation Script
    
.DESCRIPTION
    This script automates the Microsoft 365 user onboarding process by handling 
    account setup, license assignment, group memberships, and security configurations.
    
    The script connects to Microsoft Graph and Exchange Online to perform comprehensive
    user provisioning tasks including mailbox creation, security group assignments,
    and access permissions configuration.

.PARAMETER Interactive
    Enable interactive mode where the script prompts for each required value.
    Cannot be used with -InputCsv parameter.

.PARAMETER InputCsv
    Path to CSV file containing user data for batch processing.
    Cannot be used with -Interactive parameter.
    Expected columns: DisplayName, UserPrincipalName, LicenseSku, Groups
    Optional columns: FirstName, LastName, Department, JobTitle, Manager

.PARAMETER DefaultLicenseSku
    Default license SKU to assign when not specified per user (default: 'ENTERPRISEPACK')

.PARAMETER DefaultGroups
    Default security groups to assign to all users (default: 'All-Employees')

.PARAMETER MailTemplatePath
    Path to email template file for onboarding notifications (optional)

.PARAMETER UserPrincipalName
    The User Principal Name (UPN) of the user to onboard (e.g., user@domain.com)
    Required for SingleUser mode.

.PARAMETER DisplayName
    The display name for the new user account
    Required for SingleUser mode.

.PARAMETER FirstName
    The first name of the user
    Required for SingleUser mode.

.PARAMETER LastName
    The last name of the user
    Required for SingleUser mode.

.PARAMETER Department
    The department the user belongs to (optional)

.PARAMETER JobTitle
    The job title for the user (optional)

.PARAMETER Manager
    The UPN of the user's manager (optional)

.PARAMETER LicenseSku
    The license SKU to assign to the user (overrides DefaultLicenseSku)

.PARAMETER SecurityGroups
    Array of additional security group names to add the user to (in addition to DefaultGroups)

.PARAMETER DistributionGroups
    Array of distribution group names to add the user to

.PARAMETER OutputPath
    Path for the onboarding report CSV file (default: current directory with timestamp)

.EXAMPLE
    # Single User Mode (default)
    .\New-M365Onboarding.ps1 -UserPrincipalName "john.doe@company.com" -DisplayName "John Doe" -FirstName "John" -LastName "Doe"
    
.EXAMPLE
    # Single User Mode with all parameters
    .\New-M365Onboarding.ps1 -UserPrincipalName "jane.smith@company.com" -DisplayName "Jane Smith" -FirstName "Jane" -LastName "Smith" -Department "HR" -JobTitle "HR Manager" -Manager "manager@company.com" -LicenseSku "ENTERPRISEPACK" -SecurityGroups @("HR-Team") -DistributionGroups @("HR-Updates", "Company-News")

.EXAMPLE
    # Interactive Mode
    .\New-M365Onboarding.ps1 -Interactive
    
.EXAMPLE
    # Interactive Mode with custom defaults
    .\New-M365Onboarding.ps1 -Interactive -DefaultLicenseSku "E5_LICENSE" -DefaultGroups @("All-Staff", "Remote-Workers")
    
.EXAMPLE
    # Batch Mode with CSV file
    .\New-M365Onboarding.ps1 -InputCsv "C:\Data\NewUsers.csv"
    
.EXAMPLE
    # Batch Mode with custom settings
    .\New-M365Onboarding.ps1 -InputCsv "C:\Data\NewUsers.csv" -DefaultLicenseSku "BUSINESS_PREMIUM" -MailTemplatePath "C:\Templates\Welcome.html"

.NOTES
    File Name      : New-M365Onboarding.ps1
    Author         : Jonathan Costin
    Email          : jonathanc@7layerit.com
    Version        : 1.0.0
    Date Created   : December 2024
    
    Prerequisites:
    - ExchangeOnlineManagement PowerShell module
    - Microsoft.Graph PowerShell module
    - Appropriate Microsoft 365 administrator permissions
    - Network connectivity to Microsoft 365 services
    
    Change Log:
    v1.0.0 - Initial script creation with basic onboarding functionality
#>

[CmdletBinding(DefaultParameterSetName = 'SingleUser')]
param(
    # Mode Selection Parameters
    [Parameter(ParameterSetName = 'Interactive', Mandatory = $true, HelpMessage = "Enable interactive mode to prompt for each value")]
    [switch]$Interactive,
    
    [Parameter(ParameterSetName = 'BatchMode', Mandatory = $true, HelpMessage = "Path to CSV file containing user data for batch processing")]
    [ValidateScript({Test-Path $_ -PathType 'Leaf'})]
    [string]$InputCsv,
    
    # Default Configuration Parameters
    [Parameter(Mandatory = $false, HelpMessage = "Default license SKU to assign when not specified per user")]
    [string]$DefaultLicenseSku = "ENTERPRISEPACK",
    
    [Parameter(Mandatory = $false, HelpMessage = "Default security groups to assign to all users")]
    [string[]]$DefaultGroups = @("All-Employees"),
    
    [Parameter(Mandatory = $false, HelpMessage = "Path to email template file for onboarding notifications")]
    [ValidateScript({if ($_ -and $_ -ne "") { Test-Path $_ -PathType 'Leaf' } else { $true }})]
    [string]$MailTemplatePath = "",
    
    # Single User Mode Parameters (original parameters)
    [Parameter(ParameterSetName = 'SingleUser', Mandatory = $true, HelpMessage = "User Principal Name (UPN) of the user to onboard")]
    [ValidatePattern("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")]
    [string]$UserPrincipalName,
    
    [Parameter(ParameterSetName = 'SingleUser', Mandatory = $true, HelpMessage = "Display name for the user")]
    [ValidateNotNullOrEmpty()]
    [string]$DisplayName,
    
    [Parameter(ParameterSetName = 'SingleUser', Mandatory = $true, HelpMessage = "First name of the user")]
    [ValidateNotNullOrEmpty()]
    [string]$FirstName,
    
    [Parameter(ParameterSetName = 'SingleUser', Mandatory = $true, HelpMessage = "Last name of the user")]
    [ValidateNotNullOrEmpty()]
    [string]$LastName,
    
    [Parameter(ParameterSetName = 'SingleUser', Mandatory = $false, HelpMessage = "Department the user belongs to")]
    [string]$Department = "",
    
    [Parameter(ParameterSetName = 'SingleUser', Mandatory = $false, HelpMessage = "Job title for the user")]
    [string]$JobTitle = "",
    
    [Parameter(ParameterSetName = 'SingleUser', Mandatory = $false, HelpMessage = "UPN of the user's manager")]
    [ValidatePattern("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$|^$")]
    [string]$Manager = "",
    
    [Parameter(ParameterSetName = 'SingleUser', Mandatory = $false, HelpMessage = "License SKU to assign to the user (overrides default)")]
    [string]$LicenseSku = "",
    
    [Parameter(ParameterSetName = 'SingleUser', Mandatory = $false, HelpMessage = "Array of security group names to add the user to (in addition to defaults)")]
    [string[]]$SecurityGroups = @(),
    
    [Parameter(ParameterSetName = 'SingleUser', Mandatory = $false, HelpMessage = "Array of distribution group names to add the user to")]
    [string[]]$DistributionGroups = @(),
    
    [Parameter(Mandatory = $false, HelpMessage = "Path for the onboarding report CSV file")]
    [string]$OutputPath = ".\M365_Onboarding_Report_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
)

# ============================================================================
# PARAMETER VALIDATION AND MODE HANDLING
# ============================================================================

# Validate mutual exclusivity of modes (enforced by parameter sets)
if ($Interactive -and $InputCsv) {
    Write-Error "Cannot use both -Interactive and -InputCsv parameters simultaneously. Please choose one mode." -ErrorAction Stop
}

# ============================================================================
# HELPER FUNCTIONS FOR DATA INGESTION
# ============================================================================

# Function to get available license SKUs from tenant
function Get-TenantLicenseSkus {
    try {
        Write-Host "  Retrieving available license SKUs from tenant..." -ForegroundColor Cyan
        $licenses = Get-MgSubscribedSku | Where-Object { $_.PrepaidUnits.Enabled -gt 0 }
        return $licenses | Select-Object SkuPartNumber, @{Name='AvailableUnits';Expression={$_.PrepaidUnits.Enabled - $_.ConsumedUnits}}, @{Name='DisplayName';Expression={$_.SkuPartNumber}}
    }
    catch {
        Write-Warning "Failed to retrieve license SKUs: $($_.Exception.Message)"
        return @()
    }
}

# Function to get available groups from tenant
function Get-TenantGroups {
    param(
        [string]$GroupType = "All" # All, Security, Distribution
    )
    try {
        Write-Host "  Retrieving available groups from tenant..." -ForegroundColor Cyan
        $groups = Get-MgGroup -All
        
        switch ($GroupType) {
            "Security" { return $groups | Where-Object { $_.SecurityEnabled -eq $true } | Select-Object DisplayName, Id, GroupTypes }
            "Distribution" { return $groups | Where-Object { $_.SecurityEnabled -eq $false } | Select-Object DisplayName, Id, GroupTypes }
            default { return $groups | Select-Object DisplayName, Id, GroupTypes, SecurityEnabled }
        }
    }
    catch {
        Write-Warning "Failed to retrieve groups: $($_.Exception.Message)"
        return @()
    }
}

# Function to validate user data
function Test-UserData {
    param(
        [PSCustomObject]$UserData,
        [array]$AvailableLicenses,
        [array]$AvailableGroups
    )
    
    $errors = @()
    
    # Validate required fields
    if ([string]::IsNullOrWhiteSpace($UserData.DisplayName)) {
        $errors += "DisplayName is required"
    }
    
    if ([string]::IsNullOrWhiteSpace($UserData.UserPrincipalName)) {
        $errors += "UserPrincipalName is required"
    } elseif (-not ($UserData.UserPrincipalName -match "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")) {
        $errors += "UserPrincipalName has invalid email format"
    }
    
    # Validate license SKU
    if (-not [string]::IsNullOrWhiteSpace($UserData.LicenseSku)) {
        if ($AvailableLicenses.Count -gt 0 -and $UserData.LicenseSku -notin $AvailableLicenses.SkuPartNumber) {
            $errors += "License SKU '$($UserData.LicenseSku)' is not available in tenant"
        }
    }
    
    # Validate groups (if specified)
    if (-not [string]::IsNullOrWhiteSpace($UserData.Groups)) {
        $userGroups = $UserData.Groups -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }
        if ($AvailableGroups.Count -gt 0) {
            foreach ($group in $userGroups) {
                if ($group -notin $AvailableGroups.DisplayName) {
                    $errors += "Group '$group' does not exist in tenant"
                }
            }
        }
    }
    
    # Validate manager UPN if specified
    if (-not [string]::IsNullOrWhiteSpace($UserData.Manager)) {
        if (-not ($UserData.Manager -match "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")) {
            $errors += "Manager UPN has invalid email format"
        }
    }
    
    return $errors
}

# Handle Interactive Mode
if ($Interactive) {
    Write-Host "=" * 80 -ForegroundColor Magenta
    Write-Host "  INTERACTIVE MODE - User Input Required" -ForegroundColor Magenta
    Write-Host "=" * 80 -ForegroundColor Magenta
    Write-Host ""
    
    # Connect to Microsoft Graph first to get tenant data
    try {
        Write-Host "Connecting to Microsoft Graph to retrieve tenant information..." -ForegroundColor Green
        $context = Get-MgContext -ErrorAction SilentlyContinue
        if (-not $context) {
            Connect-MgGraph -Scopes "User.ReadWrite.All", "Group.ReadWrite.All", "Directory.ReadWrite.All" -NoWelcome
        }
        
        # Get available licenses and groups
        $availableLicenses = Get-TenantLicenseSkus
        $availableGroups = Get-TenantGroups
        
        Write-Host "Retrieved $($availableLicenses.Count) license SKUs and $($availableGroups.Count) groups from tenant." -ForegroundColor Green
        Write-Host ""
    }
    catch {
        Write-Warning "Could not retrieve tenant information: $($_.Exception.Message)"
        $availableLicenses = @()
        $availableGroups = @()
    }
    
    # Prompt for each required value
    $UserPrincipalName = Read-Host "Enter User Principal Name (e.g., user@domain.com)"
    while (-not ($UserPrincipalName -match "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")) {
        Write-Host "Invalid email format. Please try again." -ForegroundColor Red
        $UserPrincipalName = Read-Host "Enter User Principal Name (e.g., user@domain.com)"
    }
    
    $DisplayName = Read-Host "Enter Display Name"
    while ([string]::IsNullOrWhiteSpace($DisplayName)) {
        Write-Host "Display Name cannot be empty. Please try again." -ForegroundColor Red
        $DisplayName = Read-Host "Enter Display Name"
    }
    
    $FirstName = Read-Host "Enter First Name"
    while ([string]::IsNullOrWhiteSpace($FirstName)) {
        Write-Host "First Name cannot be empty. Please try again." -ForegroundColor Red
        $FirstName = Read-Host "Enter First Name"
    }
    
    $LastName = Read-Host "Enter Last Name"
    while ([string]::IsNullOrWhiteSpace($LastName)) {
        Write-Host "Last Name cannot be empty. Please try again." -ForegroundColor Red
        $LastName = Read-Host "Enter Last Name"
    }
    
    # Optional fields with defaults
    $Department = Read-Host "Enter Department (optional)"
    $JobTitle = Read-Host "Enter Job Title (optional)"
    
    $Manager = Read-Host "Enter Manager UPN (optional, e.g., manager@domain.com)"
    if ($Manager -and -not ($Manager -match "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")) {
        Write-Host "Invalid manager email format. Clearing value." -ForegroundColor Yellow
        $Manager = ""
    }
    
    # License SKU selection from available tenant SKUs
    if ($availableLicenses.Count -gt 0) {
        Write-Host ""
        Write-Host "Available License SKUs:" -ForegroundColor Cyan
        for ($i = 0; $i -lt $availableLicenses.Count; $i++) {
            $license = $availableLicenses[$i]
            Write-Host "  [$($i + 1)] $($license.SkuPartNumber) (Available: $($license.AvailableUnits))" -ForegroundColor White
        }
        Write-Host "  [0] Use default: $DefaultLicenseSku" -ForegroundColor White
        
        do {
            $licenseChoice = Read-Host "Select license SKU by number (0-$($availableLicenses.Count))"
            $licenseIndex = [int]$licenseChoice - 1
        } while ($licenseChoice -notmatch '^\d+$' -or [int]$licenseChoice -lt 0 -or [int]$licenseChoice -gt $availableLicenses.Count)
        
        if ([int]$licenseChoice -eq 0) {
            $LicenseSku = $DefaultLicenseSku
        } else {
            $LicenseSku = $availableLicenses[$licenseIndex].SkuPartNumber
        }
    } else {
        $LicenseInput = Read-Host "Enter License SKU (press Enter for default: $DefaultLicenseSku)"
        $LicenseSku = if ([string]::IsNullOrWhiteSpace($LicenseInput)) { $DefaultLicenseSku } else { $LicenseInput }
    }
    
    # Group selection from available tenant groups
    if ($availableGroups.Count -gt 0) {
        Write-Host ""
        Write-Host "Available Groups (showing first 20):" -ForegroundColor Cyan
        $displayGroups = $availableGroups | Select-Object -First 20
        for ($i = 0; $i -lt $displayGroups.Count; $i++) {
            $group = $displayGroups[$i]
            $groupType = if ($group.SecurityEnabled) { "Security" } else { "Distribution" }
            Write-Host "  [$($i + 1)] $($group.DisplayName) ($groupType)" -ForegroundColor White
        }
        
        $groupSelection = Read-Host "Enter group numbers (comma-separated) or group names (comma-separated), or press Enter to skip"
        if (-not [string]::IsNullOrWhiteSpace($groupSelection)) {
            $selectedGroups = @()
            $selections = $groupSelection.Split(',').Trim() | Where-Object { $_ -ne "" }
            
            foreach ($selection in $selections) {
                if ($selection -match '^\d+$') {
                    # Numeric selection
                    $index = [int]$selection - 1
                    if ($index -ge 0 -and $index -lt $displayGroups.Count) {
                        $selectedGroups += $displayGroups[$index].DisplayName
                    }
                } else {
                    # Group name selection
                    if ($selection -in $availableGroups.DisplayName) {
                        $selectedGroups += $selection
                    } else {
                        Write-Host "Warning: Group '$selection' not found in tenant" -ForegroundColor Yellow
                    }
                }
            }
            $SecurityGroups = $selectedGroups
        } else {
            $SecurityGroups = @()
        }
    } else {
        # Fallback to manual entry
        $SecurityGroupsInput = Read-Host "Enter additional Security Groups (comma-separated, optional)"
        $SecurityGroups = if ([string]::IsNullOrWhiteSpace($SecurityGroupsInput)) { 
            @() 
        } else { 
            $SecurityGroupsInput.Split(',').Trim() | Where-Object { $_ -ne "" }
        }
    }
    
    # Distribution Groups (separate from security groups)
    $DistributionGroupsInput = Read-Host "Enter Distribution Groups (comma-separated, optional)"
    $DistributionGroups = if ([string]::IsNullOrWhiteSpace($DistributionGroupsInput)) { 
        @() 
    } else { 
        $DistributionGroupsInput.Split(',').Trim() | Where-Object { $_ -ne "" }
    }
    
    Write-Host ""
    Write-Host "Interactive input completed." -ForegroundColor Green
}

# Handle Batch Mode
if ($InputCsv) {
    Write-Host "=" * 80 -ForegroundColor Magenta
    Write-Host "  BATCH MODE - Processing CSV File: $InputCsv" -ForegroundColor Magenta
    Write-Host "=" * 80 -ForegroundColor Magenta
    Write-Host ""
    
    # Initialize arrays for processing
    $BatchUsers = @()
    $ValidationErrors = @()
    
    try {
        # Read and parse CSV file
        Write-Host "Reading CSV file: $InputCsv" -ForegroundColor Cyan
        $csvData = Import-Csv -Path $InputCsv
        
        if ($csvData.Count -eq 0) {
            throw "CSV file is empty or has no valid data rows"
        }
        
        Write-Host "Found $($csvData.Count) user records in CSV file" -ForegroundColor Green
        
        # Validate CSV columns
        $requiredColumns = @('DisplayName', 'UserPrincipalName', 'LicenseSku', 'Groups')
        $csvColumns = $csvData[0].PSObject.Properties.Name
        $missingColumns = $requiredColumns | Where-Object { $_ -notin $csvColumns }
        
        if ($missingColumns.Count -gt 0) {
            throw "CSV file is missing required columns: $($missingColumns -join ', '). Expected columns: $($requiredColumns -join ', ')"
        }
        
        Write-Host "CSV file has all required columns" -ForegroundColor Green
        
        # Connect to Microsoft Graph to get tenant data for validation
        try {
            Write-Host "Connecting to Microsoft Graph for validation..." -ForegroundColor Cyan
            $context = Get-MgContext -ErrorAction SilentlyContinue
            if (-not $context) {
                Connect-MgGraph -Scopes "User.ReadWrite.All", "Group.ReadWrite.All", "Directory.ReadWrite.All" -NoWelcome
            }
            
            # Get available licenses and groups for validation
            $availableLicenses = Get-TenantLicenseSkus
            $availableGroups = Get-TenantGroups
            
            Write-Host "Retrieved tenant information for validation" -ForegroundColor Green
        }
        catch {
            Write-Warning "Could not retrieve tenant information for validation: $($_.Exception.Message)"
            $availableLicenses = @()
            $availableGroups = @()
        }
        
        # Process and validate each user record
        Write-Host "Validating user records..." -ForegroundColor Cyan
        
        for ($i = 0; $i -lt $csvData.Count; $i++) {
            $user = $csvData[$i]
            $rowNumber = $i + 2  # +2 because CSV has header row and we're 0-indexed
            
            Write-Progress -Activity "Validating user records" -Status "Processing row $rowNumber" -PercentComplete (($i + 1) / $csvData.Count * 100)
            
            # Create standardized user object
            $userObject = [PSCustomObject]@{
                RowNumber = $rowNumber
                DisplayName = $user.DisplayName?.Trim()
                UserPrincipalName = $user.UserPrincipalName?.Trim()
                FirstName = $user.FirstName?.Trim()
                LastName = $user.LastName?.Trim()
                Department = $user.Department?.Trim()
                JobTitle = $user.JobTitle?.Trim()
                Manager = $user.Manager?.Trim()
                LicenseSku = if ([string]::IsNullOrWhiteSpace($user.LicenseSku?.Trim())) { $DefaultLicenseSku } else { $user.LicenseSku.Trim() }
                Groups = $user.Groups?.Trim()
                SecurityGroups = @()
                DistributionGroups = @()
                ValidationErrors = @()
            }
            
            # Parse groups (assuming Groups column contains comma-separated values)
            if (-not [string]::IsNullOrWhiteSpace($userObject.Groups)) {
                $groupList = $userObject.Groups -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }
                # For now, treat all groups as security groups (can be enhanced later)
                $userObject.SecurityGroups = $groupList
            }
            
            # Validate user data
            $errors = Test-UserData -UserData $userObject -AvailableLicenses $availableLicenses -AvailableGroups $availableGroups
            
            if ($errors.Count -gt 0) {
                $userObject.ValidationErrors = $errors
                $ValidationErrors += [PSCustomObject]@{
                    RowNumber = $rowNumber
                    UserPrincipalName = $userObject.UserPrincipalName
                    DisplayName = $userObject.DisplayName
                    Errors = ($errors -join '; ')
                }
                
                Write-Host "  Row $rowNumber ($($userObject.UserPrincipalName)): $($errors.Count) validation error(s)" -ForegroundColor Red
            } else {
                Write-Host "  Row $rowNumber ($($userObject.UserPrincipalName)): Validation passed" -ForegroundColor Green
            }
            
            $BatchUsers += $userObject
        }
        
        Write-Progress -Activity "Validating user records" -Completed
        
        # Display validation summary
        Write-Host ""
        Write-Host "Validation Summary:" -ForegroundColor Yellow
        Write-Host "  Total users processed: $($BatchUsers.Count)" -ForegroundColor White
        Write-Host "  Users with validation errors: $($ValidationErrors.Count)" -ForegroundColor White
        Write-Host "  Users ready for processing: $($BatchUsers.Count - $ValidationErrors.Count)" -ForegroundColor White
        
        # Show validation errors if any
        if ($ValidationErrors.Count -gt 0) {
            Write-Host ""
            Write-Host "Validation Errors Found:" -ForegroundColor Red
            foreach ($error in $ValidationErrors) {
                Write-Host "  Row $($error.RowNumber) - $($error.UserPrincipalName): $($error.Errors)" -ForegroundColor Red
            }
            
            # Export validation errors to separate file
            $errorPath = $OutputPath -replace '\.csv$', '_ValidationErrors.csv'
            $ValidationErrors | Export-Csv -Path $errorPath -NoTypeInformation
            Write-Host ""
            Write-Host "Validation errors exported to: $errorPath" -ForegroundColor Yellow
            
            # Ask user if they want to continue with valid records only
            Write-Host ""
            $continueChoice = Read-Host "Do you want to continue processing only the valid records? (Y/N)"
            if ($continueChoice -notmatch '^[Yy]') {
                Write-Host "Batch processing cancelled due to validation errors." -ForegroundColor Yellow
                exit 1
            }
            
            # Filter out users with validation errors
            $BatchUsers = $BatchUsers | Where-Object { $_.ValidationErrors.Count -eq 0 }
        }
        
        Write-Host ""
        Write-Host "Batch validation completed. Ready to process $($BatchUsers.Count) valid user(s)." -ForegroundColor Green
        
        # Store batch users for processing
        $script:BatchUsers = $BatchUsers
        
    }
    catch {
        Write-Host ""
        Write-Host "Error processing CSV file: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

# Combine default groups with user-specified groups
if ($SecurityGroups.Count -gt 0) {
    $SecurityGroups = $DefaultGroups + $SecurityGroups | Select-Object -Unique
} else {
    $SecurityGroups = $DefaultGroups
}

# Use default license if not specified
if ([string]::IsNullOrWhiteSpace($LicenseSku)) {
    $LicenseSku = $DefaultLicenseSku
}

# ============================================================================
# SCRIPT BANNER
# ============================================================================
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "  MICROSOFT 365 USER ONBOARDING AUTOMATION SCRIPT" -ForegroundColor Cyan
Write-Host "  Version: 1.0.0" -ForegroundColor Cyan
Write-Host "  Author: Jonathan Costin (jonathanc@7layerit.com)" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host ""

# Display onboarding parameters
Write-Host "Onboarding Configuration:" -ForegroundColor Yellow
Write-Host "  User Principal Name: $UserPrincipalName" -ForegroundColor White
Write-Host "  Display Name: $DisplayName" -ForegroundColor White
Write-Host "  First Name: $FirstName" -ForegroundColor White
Write-Host "  Last Name: $LastName" -ForegroundColor White
if ($Department) { Write-Host "  Department: $Department" -ForegroundColor White }
if ($JobTitle) { Write-Host "  Job Title: $JobTitle" -ForegroundColor White }
if ($Manager) { Write-Host "  Manager: $Manager" -ForegroundColor White }
if ($LicenseSku) { Write-Host "  License SKU: $LicenseSku" -ForegroundColor White }
if ($SecurityGroups.Count -gt 0) { Write-Host "  Security Groups: $($SecurityGroups -join ', ')" -ForegroundColor White }
if ($DistributionGroups.Count -gt 0) { Write-Host "  Distribution Groups: $($DistributionGroups -join ', ')" -ForegroundColor White }
Write-Host "  Report Output: $OutputPath" -ForegroundColor White
Write-Host ""

# ============================================================================
# MAIN EXECUTION
# ============================================================================

# Initialize results array for reporting
$OnboardingResults = @()

try {
    # Step 1: Connect to Microsoft Graph
    Write-Host "Step 1: Connecting to Microsoft Graph..." -ForegroundColor Green
    try {
        # Check if already connected
        $context = Get-MgContext -ErrorAction SilentlyContinue
        if ($context) {
            Write-Host "  Already connected to Microsoft Graph as: $($context.Account)" -ForegroundColor Yellow
        } else {
            # Connect with required scopes for user management
            Connect-MgGraph -Scopes "User.ReadWrite.All", "Group.ReadWrite.All", "Directory.ReadWrite.All" -NoWelcome
            Write-Host "  Successfully connected to Microsoft Graph" -ForegroundColor Green
        }
    }
    catch {
        throw "Failed to connect to Microsoft Graph: $($_.Exception.Message)"
    }

    # Step 2: Connect to Exchange Online
    Write-Host "Step 2: Connecting to Exchange Online..." -ForegroundColor Green
    try {
        # Check if already connected
        $session = Get-PSSession | Where-Object { $_.ConfigurationName -eq "Microsoft.Exchange" -and $_.State -eq "Opened" }
        if ($session) {
            Write-Host "  Already connected to Exchange Online" -ForegroundColor Yellow
        } else {
            Connect-ExchangeOnline -ShowBanner:$false
            Write-Host "  Successfully connected to Exchange Online" -ForegroundColor Green
        }
    }
    catch {
        throw "Failed to connect to Exchange Online: $($_.Exception.Message)"
    }

    # Step 3: User Account Creation
    Write-Host "Step 3: Creating user account..." -ForegroundColor Green
    # TODO: Add user creation logic here
    Write-Host "  User account creation - Ready for implementation" -ForegroundColor Yellow
    
    # Step 4: License Assignment
    if ($LicenseSku) {
        Write-Host "Step 4: Assigning licenses..." -ForegroundColor Green
        # TODO: Add license assignment logic here
        Write-Host "  License assignment - Ready for implementation" -ForegroundColor Yellow
    }
    
    # Step 5: Security Group Assignments
    if ($SecurityGroups.Count -gt 0) {
        Write-Host "Step 5: Adding user to security groups..." -ForegroundColor Green
        # TODO: Add security group assignment logic here
        Write-Host "  Security group assignments - Ready for implementation" -ForegroundColor Yellow
    }
    
    # Step 6: Distribution Group Assignments
    if ($DistributionGroups.Count -gt 0) {
        Write-Host "Step 6: Adding user to distribution groups..." -ForegroundColor Green
        # TODO: Add distribution group assignment logic here
        Write-Host "  Distribution group assignments - Ready for implementation" -ForegroundColor Yellow
    }
    
    # Step 7: Generate Report
    Write-Host "Step 7: Generating onboarding report..." -ForegroundColor Green
    $OnboardingResults += [PSCustomObject]@{
        UserPrincipalName = $UserPrincipalName
        DisplayName = $DisplayName
        Department = $Department
        JobTitle = $JobTitle
        Manager = $Manager
        LicenseSku = $LicenseSku
        SecurityGroups = ($SecurityGroups -join '; ')
        DistributionGroups = ($DistributionGroups -join '; ')
        OnboardingDate = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        Status = "Template Created - Ready for Implementation"
    }
    
    # Export results to CSV
    $OnboardingResults | Export-Csv -Path $OutputPath -NoTypeInformation
    Write-Host "  Report exported to: $OutputPath" -ForegroundColor Green

    Write-Host ""
    Write-Host "=" * 80 -ForegroundColor Green
    Write-Host "  ONBOARDING SCRIPT TEMPLATE COMPLETED SUCCESSFULLY" -ForegroundColor Green
    Write-Host "  Ready for implementation of actual onboarding logic" -ForegroundColor Green
    Write-Host "=" * 80 -ForegroundColor Green
}
catch {
    Write-Host ""
    Write-Host "=" * 80 -ForegroundColor Red
    Write-Host "  ERROR: ONBOARDING SCRIPT FAILED" -ForegroundColor Red
    Write-Host "  Error Details: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "=" * 80 -ForegroundColor Red
    
    # Add error to results
    $OnboardingResults += [PSCustomObject]@{
        UserPrincipalName = $UserPrincipalName
        DisplayName = $DisplayName
        Department = $Department
        JobTitle = $JobTitle
        Manager = $Manager
        LicenseSku = $LicenseSku
        SecurityGroups = ($SecurityGroups -join '; ')
        DistributionGroups = ($DistributionGroups -join '; ')
        OnboardingDate = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        Status = "FAILED: $($_.Exception.Message)"
    }
    
    # Export error results to CSV
    if ($OnboardingResults.Count -gt 0) {
        $OnboardingResults | Export-Csv -Path $OutputPath -NoTypeInformation
        Write-Host "Error report exported to: $OutputPath" -ForegroundColor Yellow
    }
    
    exit 1
}
finally {
    # Cleanup: Disconnect from services (optional - connections can be reused)
    Write-Host ""
    Write-Host "Maintaining connections for potential reuse..." -ForegroundColor Cyan
    Write-Host "Use 'Disconnect-MgGraph' and 'Disconnect-ExchangeOnline' to disconnect manually if needed." -ForegroundColor Cyan
}
