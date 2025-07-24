# Logging Module for Microsoft 365 Offboarding Script v2.1
# This module provides enhanced logging and error handling capabilities

# Initialize logging paths
$script:LogDirectory = ""
$script:ErrorLogFile = ""
$script:PasswordLogFile = ""
$script:InvalidUserLogFile = ""
$script:AuditLogFile = ""

function Initialize-LoggingSystem {
    [CmdletBinding()]
    param(
        [string]$LogDirectory = (Join-Path $PWD "logs")
    )
    
    # Create logs directory if it doesn't exist
    if (-not (Test-Path $LogDirectory)) {
        New-Item -ItemType Directory -Path $LogDirectory -Force | Out-Null
    }
    
    $script:LogDirectory = $LogDirectory
    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    
    # Set up log file paths
    $script:ErrorLogFile = Join-Path $LogDirectory "Errors_$timestamp.log"
    $script:PasswordLogFile = Join-Path $LogDirectory "Passwords_$timestamp.log"
    $script:InvalidUserLogFile = Join-Path $LogDirectory "InvalidUsers_$timestamp.log"
    $script:AuditLogFile = Join-Path $LogDirectory "Audit_$timestamp.log"
    
    # Initialize audit log
    Write-AuditLog -Message "Offboarding session started" -Level "INFO"
    
    return @{
        ErrorLogFile = $script:ErrorLogFile
        PasswordLogFile = $script:PasswordLogFile
        InvalidUserLogFile = $script:InvalidUserLogFile
        AuditLogFile = $script:AuditLogFile
    }
}

function Write-LogError {
    [CmdletBinding()]
    param(
        [string]$UPN,
        [string]$Action,
        [string]$Error
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] UPN: $UPN | Action: $Action | Error: $Error"
    
    # Write to error log file
    Add-Content -Path $script:ErrorLogFile -Value $logEntry -ErrorAction SilentlyContinue
    
    # Also write to audit log
    Write-AuditLog -Message "ERROR - $UPN - $Action - $Error" -Level "ERROR"
}

function Write-PasswordLog {
    [CmdletBinding()]
    param(
        [string]$UPN,
        [string]$Password
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] $UPN - $Password"
    
    Add-Content -Path $script:PasswordLogFile -Value $logEntry -ErrorAction SilentlyContinue
    Write-AuditLog -Message "Password reset for $UPN" -Level "INFO"
}

function Write-InvalidUserLog {
    [CmdletBinding()]
    param(
        [string]$UPN,
        [string]$Reason = "User not found"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] $UPN - $Reason"
    
    Add-Content -Path $script:InvalidUserLogFile -Value $logEntry -ErrorAction SilentlyContinue
    Write-AuditLog -Message "Invalid user: $UPN - $Reason" -Level "WARNING"
}

function Write-AuditLog {
    [CmdletBinding()]
    param(
        [string]$Message,
        [ValidateSet("INFO", "WARNING", "ERROR", "SUCCESS")]
        [string]$Level = "INFO",
        [string]$UPN = "",
        [string]$Action = ""
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level]"
    
    if ($UPN) { $logEntry += " [UPN: $UPN]" }
    if ($Action) { $logEntry += " [Action: $Action]" }
    
    $logEntry += " $Message"
    
    Add-Content -Path $script:AuditLogFile -Value $logEntry -ErrorAction SilentlyContinue
    
    # Also output to console with color coding
    switch ($Level) {
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
        default { Write-Host $logEntry -ForegroundColor Gray }
    }
}

function Write-OperationResult {
    [CmdletBinding()]
    param(
        [string]$UPN,
        [string]$Action,
        [string]$Result,
        [hashtable]$AdditionalData = @{}
    )
    
    $level = switch ($Result) {
        "Success" { "SUCCESS" }
        "Failed" { "ERROR" }
        default { "INFO" }
    }
    
    $message = "Operation completed - Result: $Result"
    if ($AdditionalData.Count -gt 0) {
        $details = ($AdditionalData.GetEnumerator() | ForEach-Object { "$($_.Key): $($_.Value)" }) -join ", "
        $message += " | Details: $details"
    }
    
    Write-AuditLog -Message $message -Level $level -UPN $UPN -Action $Action
}

function Get-LogFilePaths {
    return @{
        ErrorLogFile = $script:ErrorLogFile
        PasswordLogFile = $script:PasswordLogFile
        InvalidUserLogFile = $script:InvalidUserLogFile
        AuditLogFile = $script:AuditLogFile
        LogDirectory = $script:LogDirectory
    }
}

function Show-LogSummary {
    $paths = Get-LogFilePaths
    
    Write-Host "`n=== LOG SUMMARY ===" -ForegroundColor Cyan
    
    foreach ($logType in @("ErrorLogFile", "PasswordLogFile", "InvalidUserLogFile", "AuditLogFile")) {
        $path = $paths[$logType]
        if (Test-Path $path) {
            $lineCount = (Get-Content $path).Count
            $fileName = Split-Path $path -Leaf
            Write-Host "$fileName`: $lineCount entries" -ForegroundColor Yellow
            Write-Host "  Path: $path" -ForegroundColor Gray
        }
    }
    
    Write-Host "`nAll logs are saved in: $($paths.LogDirectory)" -ForegroundColor Green
}

function Export-LogsToZip {
    [CmdletBinding()]
    param(
        [string]$OutputPath
    )
    
    if (-not $OutputPath) {
        $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
        $OutputPath = Join-Path $PWD "OffboardingLogs_$timestamp.zip"
    }
    
    try {
        Compress-Archive -Path "$($script:LogDirectory)\*" -DestinationPath $OutputPath -Force
        Write-AuditLog -Message "Logs exported to: $OutputPath" -Level "SUCCESS"
        return $OutputPath
    }
    catch {
        Write-AuditLog -Message "Failed to export logs: $($_.Exception.Message)" -Level "ERROR"
        return $null
    }
}

# Export module functions
Export-ModuleMember -Function Initialize-LoggingSystem, Write-LogError, Write-PasswordLog, Write-InvalidUserLog, Write-AuditLog, Write-OperationResult, Get-LogFilePaths, Show-LogSummary, Export-LogsToZip
