# Connect to Exchange Online
Import-Module ExchangeOnlineManagement
Connect-ExchangeOnline 

# Path to store the settings file
$SettingsFile = "/Users/jonathancostin/files/10Scripts/mailboxaudit/MailboxReportSettings.txt"

# Function to get the report path
function Get-ReportPath
{
  # Check if the settings file exists
  if (Test-Path $SettingsFile)
  {
    # Read the stored report path
    $StoredReportPath = Get-Content $SettingsFile

    # Ask the user if they want to use the stored path or enter a new one
    Write-Host "A previous report path was found: $StoredReportPath"
    $UseStoredPath = Read-Host "Do you want to use this path? (Y/N)"

    if ($UseStoredPath -match '^[Yy]')
    {
      $ReportPath = $StoredReportPath
    } else
    {
      $ReportPath = Read-Host "Enter the path to store the report (e.g., C:\Reports\MailboxReport.csv)"
      # Ensure the directory exists
      $ReportDirectory = Split-Path $ReportPath -Parent
      if (!(Test-Path $ReportDirectory))
      {
        New-Item -ItemType Directory -Path $ReportDirectory -Force | Out-Null
      }
      # Save the new path
      Set-Content -Path $SettingsFile -Value $ReportPath
    }
  } else
  {
    # Prompt the user for the report path
    $ReportPath = Read-Host "Enter the path to store the report (e.g., C:\Reports\MailboxReport.csv)"
    # Ensure the directory exists
    $ReportDirectory = Split-Path $ReportPath -Parent
    if (!(Test-Path $ReportDirectory))
    {
      New-Item -ItemType Directory -Path $ReportDirectory -Force | Out-Null
    }
    # Save the path for future use
    Set-Content -Path $SettingsFile -Value $ReportPath
  }
  return $ReportPath
}

# Get the report path
$ReportPath = Get-ReportPath

# Get all user mailboxes 
$Mailboxes = Get-Mailbox -RecipientTypeDetails UserMailbox -ResultSize unlimited

Write-Host -ForegroundColor Green "$($Mailboxes.Count) User Mailboxes Found."

# Function to convert bytes to a readable size
function Convert-BytesToReadableSize
{
  param (
    [int64]$Bytes
  )

  switch ($Bytes)
  {
    {$_ -ge 1PB}
    { "{0:N2} PB" -f ($Bytes / 1PB); break 
    }
    {$_ -ge 1TB}
    { "{0:N2} TB" -f ($Bytes / 1TB); break 
    }
    {$_ -ge 1GB}
    { "{0:N2} GB" -f ($Bytes / 1GB); break 
    }
    {$_ -ge 1MB}
    { "{0:N2} MB" -f ($Bytes / 1MB); break 
    }
    {$_ -ge 1KB}
    { "{0:N2} KB" -f ($Bytes / 1KB); break 
    }
    default
    { "{0:N2} Bytes" -f $Bytes 
    }
  }
}

# Initialize an array to hold report data
$ReportData = @()

foreach ($Mailbox in $Mailboxes)
{
  Write-Host -ForegroundColor Green "Processing $($Mailbox.DisplayName) <$($Mailbox.PrimarySmtpAddress)>"

  # Get primary mailbox statistics
  $PrimaryStats = Get-MailboxStatistics -Identity $Mailbox.Identity

  # Extract total size of the primary mailbox
  $PrimaryMailboxSizeString = $PrimaryStats.TotalItemSize.Value.ToString()

  # Extract bytes from PrimaryMailboxSizeString, handling commas
  if ($PrimaryMailboxSizeString -match '\(([\d,]+) bytes\)')
  {
    $BytesString = $Matches[1]
    $BytesStringClean = $BytesString -replace ',', ''
    $PrimaryMailboxBytes = [int64]$BytesStringClean
  } else
  {
    $PrimaryMailboxBytes = 0
  }

  # Initialize archive variables
  $ArchiveEnabled = $false
  $ArchiveMailboxSizeString = "N/A"
  $ArchiveMailboxBytes = 0

  # Check if archive is enabled
  if ($Mailbox.ArchiveStatus -eq "Active")
  {
    $ArchiveEnabled = $true

    # Get archive mailbox statistics
    $ArchiveStats = Get-MailboxStatistics -Identity $Mailbox.Identity -Archive

    # Extract total size of the archive mailbox
    $ArchiveMailboxSizeString = $ArchiveStats.TotalItemSize.Value.ToString()

    # Extract bytes from ArchiveMailboxSizeString, handling commas
    if ($ArchiveMailboxSizeString -match '\(([\d,]+) bytes\)')
    {
      $BytesString = $Matches[1]
      $BytesStringClean = $BytesString -replace ',', ''
      $ArchiveMailboxBytes = [int64]$BytesStringClean
    } else
    {
      $ArchiveMailboxBytes = 0
    }
  }

  # Calculate Total Mailbox Bytes
  $TotalMailboxBytes = $PrimaryMailboxBytes + $ArchiveMailboxBytes

  # Convert bytes to readable sizes
  $PrimaryMailboxSizeReadable = Convert-BytesToReadableSize -Bytes $PrimaryMailboxBytes
  $ArchiveMailboxSizeReadable = if ($ArchiveEnabled)
  { Convert-BytesToReadableSize -Bytes $ArchiveMailboxBytes 
  } else
  { "N/A" 
  }
  $TotalMailboxSizeReadable   = Convert-BytesToReadableSize -Bytes $TotalMailboxBytes

  # Add data to the report
  $ReportData += [PSCustomObject]@{
    DisplayName                = $Mailbox.DisplayName
    Email                      = $Mailbox.PrimarySmtpAddress
    PrimaryMailboxSize         = $PrimaryMailboxSizeString
    PrimaryMailboxBytes        = $PrimaryMailboxBytes
    PrimaryMailboxSizeReadable = $PrimaryMailboxSizeReadable
    ArchiveEnabled             = $ArchiveEnabled
    ArchiveMailboxSize         = $ArchiveMailboxSizeString
    ArchiveMailboxBytes        = $ArchiveMailboxBytes
    ArchiveMailboxSizeReadable = $ArchiveMailboxSizeReadable
    TotalMailboxBytes          = $TotalMailboxBytes
    TotalMailboxSizeReadable   = $TotalMailboxSizeReadable
  }
}

# Sort the report data by TotalMailboxBytes in descending order
$SortedData = $ReportData | Sort-Object -Property TotalMailboxBytes -Descending

# Export the sorted data to a single CSV file
$SortedData | Export-Csv -Path $ReportPath -NoTypeInformation

Write-Host -ForegroundColor Green "Report generated at $ReportPath"

