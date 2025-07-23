write-host "Enter the all users group to base the compliant group off. (ex all users, or 'everyone') "
write-host "The complaint group is the dynamic group to force intune compliance."
param (
  [Parameter(Mandatory = $true)]
  [string]$AllUsersGroupId,

  [Parameter(Mandatory = $true)]
  [string]$CompliantUsersGroupId,

  [Parameter(Mandatory = $false)]
  [int]$MaxDevices = 10
)

# Prompt for the single base directory for all reports
$BaseReportDir = Read-Host "Enter directory where all reports will be saved"
if (-not (Test-Path -Path $BaseReportDir)) {
  New-Item -Path $BaseReportDir -ItemType Directory | Out-Null
}

Import-Module Microsoft.Graph.Users
Import-Module Microsoft.Graph.Groups
Import-Module Microsoft.Graph.DeviceManagement

# Connect to services
Connect-MgGraph `
  -Scopes "User.Read.All",`
          "DeviceManagementManagedDevices.Read.All",`
          "Directory.Read.All",`
          "User.ReadBasic.All",`
          "UserAuthenticationMethod.Read.All",`
          "AuditLog.Read.All",`
          "Policy.Read.All",`
          "GroupMember.Read.All" `
  -NoWelcome
Connect-ExchangeOnline

$CurrentDate    = Get-Date
$OneMonthAgo    = $CurrentDate.AddMonths(-1)
$SubscribedSkus = Get-MgSubscribedSku
$Users          = Get-MgUser -All `
                    -Select "id,displayName,userPrincipalName,signInActivity,assignedLicenses"

# Build a hashtable of SkuId → SkuPartNumber
$SkuMap = @{}
foreach ($Sku in $SubscribedSkus) {
  $SkuMap[$Sku.SkuId] = $Sku.SkuPartNumber
}

# Prepare result arrays
$InactiveResults = @()
$ActiveResults   = @()

function Get-AssignedLicenses {
  param (
    [Microsoft.Graph.PowerShell.Models.IMicrosoftGraphUser]$User,
    [hashtable]                                      $SkuMap
  )
  $LicenseNames = @()
  foreach ($License in $User.AssignedLicenses) {
    $SkuId = $License.SkuId
    if ($SkuMap.ContainsKey($SkuId)) {
      $LicenseNames += $SkuMap[$SkuId]
    } else {
      $LicenseNames += $SkuId
    }
  }
  return $LicenseNames -join ", "
}

function Get-LastSignInDate {
  param ([Microsoft.Graph.PowerShell.Models.IMicrosoftGraphUser]$User)
  $Last = $User.signInActivity.lastSignInDateTime
  if ($null -eq $Last) {
    return "Never"
  } else {
    return [datetime]$Last
  }
}

function Get-LastSentMessageDate {
  param ([string]$MailId)
  $HasMb = Get-Recipient -Identity $MailId -ErrorAction SilentlyContinue
  if ($null -eq $HasMb) {
    Write-Host "User $MailId does not have a mailbox."
    return "No Mailbox"
  }
  try {
    $Stats = Get-MailboxFolderStatistics `
               -Identity $MailId `
               -FolderScope SentItems `
               -IncludeOldestAndNewestItems `
               -ResultSize 5 -ErrorAction Stop
    $Folder = $Stats | Where-Object { $_.FolderType -eq 'SentItems' }
    if ($null -eq $Folder) { return "No Sent Items Folder" }
    return $Folder.NewestItemReceivedDate ?? "No Sent Emails"
  } catch {
    Write-Host "Error accessing mailbox for '$MailId': $($_.Exception.Message)"
    return "Error"
  }
}

function Get-MfaStatus {
  param ([Microsoft.Graph.PowerShell.Models.IMicrosoftGraphUser]$User)
  try {
    $authApps = Get-MgUserAuthenticationMicrosoftAuthenticatorMethod `
                  -UserId $User.Id
    $oauth    = Get-MgUserAuthenticationSoftwareOathMethod `
                  -UserId $User.Id
    $hasMfa = if ($authApps -or $oauth) { "Yes" } else { "No" }
    if ($authApps -and $oauth) { $type = "App/Token" }
    elseif ($oauth)           { $type = "Token"     }
    elseif ($authApps)        { $type = "App"       }
    else                       { $type = "SMS/None"  }
  } catch {
    Write-Host "Failed to retrieve MFA for $($User.UserPrincipalName)"
    $hasMfa = "Error"; $type = "Unknown"
  }
  return @{ HasMfa = $hasMfa; MFAType = $type }
}

function Get-UserEnrolledDevices {
  param ([Microsoft.Graph.PowerShell.Models.IMicrosoftGraphUser]$User)
  $names = @()
  try {
    $devs = Get-MgDeviceManagementManagedDevice `
              -Filter "userPrincipalName eq '$($User.UserPrincipalName)'"
    foreach ($d in $devs) { $names += $d.DeviceName }
  } catch {
    Write-Warning "Could not get devices for $($User.UserPrincipalName): $_"
  }
  return $names -join "; "
}

# Main user processing
foreach ($User in $Users) {
  Write-Host "Processing $($User.DisplayName) <$($User.UserPrincipalName)>"
  if ($User.UserPrincipalName -like "*#EXT#*") {
    Write-Host "  Skipping external user"
    continue
  }
  $lics   = Get-AssignedLicenses -User $User -SkuMap $SkuMap
  $lastSI = Get-LastSignInDate    -User $User
  $mfa    = Get-MfaStatus         -User $User
  $devs   = Get-UserEnrolledDevices -User $User

  if ($lastSI -eq "Never" -or `
      ($lastSI -is [datetime] -and $lastSI -lt $OneMonthAgo)) {
    $lastSent = Get-LastSentMessageDate -MailId $User.UserPrincipalName
    $InactiveResults += [PSCustomObject]@{
      DisplayName       = $User.DisplayName
      UserPrincipalName = $User.UserPrincipalName
      LastSignInDate    = $lastSI
      LastSentMessage   = $lastSent
      Licenses          = $lics
      HasMfa            = $mfa.HasMfa
      MFAType           = $mfa.MFAType
    }
  } else {
    $ActiveResults += [PSCustomObject]@{
      DisplayName       = $User.DisplayName
      UserPrincipalName = $User.UserPrincipalName
      Licenses          = $lics
      HasMfa            = $mfa.HasMfa
      MFAType           = $mfa.MFAType
      Devices           = $devs
    }
  }
}

# Sort & export user reports
$InactiveResults = $InactiveResults | Sort-Object -Property {
  if ($_.LastSignInDate -eq "Never")      { [datetime]::MinValue }
  elseif ($_.LastSignInDate -is [datetime]) { $_.LastSignInDate }
  else                                     { [datetime]::MinValue }
} -Descending

$InactiveCSV = Join-Path $BaseReportDir "InactiveUsers.csv"
$ActiveCSV   = Join-Path $BaseReportDir "ActiveUsers.csv"

$InactiveResults | Export-Csv -Path $InactiveCSV -NoTypeInformation
$ActiveResults   | Export-Csv -Path $ActiveCSV   -NoTypeInformation

Write-Host "User reports generated:"
Write-Host "  $InactiveCSV"
Write-Host "  $ActiveCSV"

# --- Mailbox audit ---
Write-Host "`nStarting mailbox audit..."
$MailboxCSV = Join-Path $BaseReportDir `
  ("MailboxReport_{0:yyyyMMdd_HHmmss}.csv" -f (Get-Date))

$Mailboxes = Get-Mailbox -RecipientTypeDetails UserMailbox `
             -ResultSize unlimited
Write-Host -ForegroundColor Green "$($Mailboxes.Count) mailboxes found."

function Convert-BytesToReadableSize {
  param ([int64]$Bytes)
  switch ($Bytes) {
    {$_ -ge 1PB} { "{0:N2} PB" -f ($Bytes/1PB); break }
    {$_ -ge 1TB} { "{0:N2} TB" -f ($Bytes/1TB); break }
    {$_ -ge 1GB} { "{0:N2} GB" -f ($Bytes/1GB); break }
    {$_ -ge 1MB} { "{0:N2} MB" -f ($Bytes/1MB); break }
    {$_ -ge 1KB} { "{0:N2} KB" -f ($Bytes/1KB); break }
    default     { "{0:N2} Bytes" -f $Bytes }
  }
}

$ReportData = @()
foreach ($mb in $Mailboxes) {
  Write-Host -ForegroundColor Green "  Processing $($mb.DisplayName)"
  $stats   = Get-MailboxStatistics -Identity $mb.Identity
  $sizeStr = $stats.TotalItemSize.Value.ToString()
  if ($sizeStr -match '\(([\d,]+) bytes\)') {
    $priBytes = [int64]($Matches[1] -replace ',', '')
  } else { $priBytes = 0 }

  $archEnabled = $false
  $archBytes   = 0
  $archStr     = "N/A"
  if ($mb.ArchiveStatus -eq "Active") {
    $archEnabled = $true
    $astats      = Get-MailboxStatistics -Identity $mb.Identity -Archive
    $archStr     = $astats.TotalItemSize.Value.ToString()
    if ($archStr -match '\(([\d,]+) bytes\)') {
      $archBytes = [int64]($Matches[1] -replace ',', '')
    }
  }

  $totalBytes = $priBytes + $archBytes
  $ReportData += [PSCustomObject]@{
    DisplayName                = $mb.DisplayName
    Email                      = $mb.PrimarySmtpAddress
    PrimaryMailboxSize         = $sizeStr
    PrimaryMailboxBytes        = $priBytes
    PrimaryMailboxSizeReadable = Convert-BytesToReadableSize -Bytes $priBytes
    ArchiveEnabled             = $archEnabled
    ArchiveMailboxSize         = $archStr
    ArchiveMailboxBytes        = $archBytes
    ArchiveMailboxSizeReadable = if ($archEnabled) {
                                     Convert-BytesToReadableSize -Bytes $archBytes
                                   } else { "N/A" }
    TotalMailboxBytes          = $totalBytes
    TotalMailboxSizeReadable   = Convert-BytesToReadableSize -Bytes $totalBytes
  }
}

$ReportData | Sort-Object TotalMailboxBytes -Descending `
  | Export-Csv -Path $MailboxCSV -NoTypeInformation

Write-Host -ForegroundColor Green "Mailbox audit at $MailboxCSV"

# --- Intune Compliance Audit ---
# Ensure modules installed
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.DeviceManagement)) {
  Write-Host "Installing Microsoft.Graph.DeviceManagement..."
  Install-Module Microsoft.Graph.DeviceManagement -Scope CurrentUser `
    -Force -AllowClobber
}
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Groups)) {
  Write-Host "Installing Microsoft.Graph.Groups..."
  Install-Module Microsoft.Graph.Groups -Scope CurrentUser `
    -Force -AllowClobber
}
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Users)) {
  Write-Host "Installing Microsoft.Graph.Users..."
  Install-Module Microsoft.Graph.Users -Scope CurrentUser `
    -Force -AllowClobber
}

# Tenant & OutputFile name
try {
  $org        = Get-MgOrganization -ErrorAction Stop
  $tenantName = $org.DisplayName
} catch {
  Write-Warning "Could not get tenant name: $($_.Exception.Message)"
  $tenantName = "UnknownTenant"
}
$safeTenant = $tenantName -replace '[^A-Za-z0-9\-]', '_'
$ts         = Get-Date -Format 'yyyyMMdd_HHmmss'
$baseName   = "IntuneComplianceAudit_${safeTenant}_${ts}.csv"
$OutputFile = Join-Path $BaseReportDir $baseName

Write-Host "`nIntune audit will export to: $OutputFile" -ForegroundColor Cyan

# Build compliant-users hash
$compliantUsersHash = @{}
Write-Host "Building list of users in compliant group ($CompliantUsersGroupId)..."
try {
  $compliantMembers = Get-MgGroupMember -GroupId $CompliantUsersGroupId `
                        -All -ErrorAction Stop
  foreach ($m in $compliantMembers) {
    if ($m.AdditionalProperties.'@odata.type' -eq `
        '#microsoft.graph.user') {
      $compliantUsersHash[$m.Id] = $true
    }
  }
  Write-Host "Found $($compliantUsersHash.Count) users in compliant group." `
    -ForegroundColor Green
} catch {
  Write-Error "Failed to get compliant group members: $($_.Exception.Message)"
}

function Get-UserPrimaryDevices {
  param (
    [Parameter(Mandatory = $true)][string]$UserId,
    [Parameter(Mandatory = $true)][string]$UserPrincipalName
  )
  $userDevices = [System.Collections.Generic.Dictionary[string,PSObject]]::new()
  try {
    $allDevices = Get-MgDeviceManagementManagedDevice -All `
                   -ErrorAction Stop
    foreach ($dev in $allDevices) {
      $isPrimary  = $dev.UserId -eq $UserId
      $isEnroller = $dev.EnrolledByUserId -eq $UserId
      if ($isPrimary -or $isEnroller) {
        if ($userDevices.ContainsKey($dev.Id)) {
          if ($isPrimary)  { $userDevices[$dev.Id].IsPrimaryUser = $true }
          if ($isEnroller) { $userDevices[$dev.Id].IsEnroller    = $true }
        } else {
          $isCompliant = $dev.ComplianceState -match '(?i)compliant'
          $obj = [PSCustomObject]@{
            Id              = $dev.Id
            DeviceName      = $dev.DeviceName
            OperatingSystem = $dev.OperatingSystem
            OsVersion       = $dev.OsVersion
            ComplianceState = $dev.ComplianceState
            IsCompliant     = $isCompliant
            LastSyncDateTime   = $dev.LastSyncDateTime
            EnrolledDateTime   = $dev.EnrolledDateTime
            IsPrimaryUser      = $isPrimary
            IsEnroller         = $isEnroller
          }
          $userDevices.Add($dev.Id, $obj)
        }
      }
    }
    return $userDevices.Values
  } catch {
    Write-Warning "Error retrieving devices for $UserPrincipalName $_"
    return @()
  }
}

# Main Intune user loop
$allUserRecords = [System.Collections.Generic.List[PSObject]]::new()
Write-Host "Processing users from 'All Users' group ($AllUsersGroupId)..."
try {
  $groupMembers = Get-MgGroupMember -GroupId $AllUsersGroupId -All `
                   -ErrorAction Stop
  $userMembers  = $groupMembers | Where-Object {
    $_.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.user'
  }
  $totalUsers   = $userMembers.Count
  $counter      = 0

  foreach ($member in $userMembers) {
    $user = Get-MgUser -UserId $member.Id `
            -Property Id,UserPrincipalName,DisplayName `
            -ErrorAction SilentlyContinue
    if (-not $user) {
      Write-Warning "Could not retrieve user $($member.Id)"
      continue
    }
    $counter++
    $upn   = $user.UserPrincipalName
    $disp  = $user.DisplayName
    $pct   = [math]::Round(($counter/$totalUsers)*100, 2)
    Write-Progress -Activity "Processing Users" `
                   -Status "User $counter/$totalUsers ($upn)" `
                   -PercentComplete $pct

    $inComp = $compliantUsersHash.ContainsKey($user.Id)
    $devs   = Get-UserPrimaryDevices -UserId $user.Id `
               -UserPrincipalName $upn

    $rec = [ordered]@{
      UserPrincipalName  = $upn
      DisplayName        = $disp
      IsInCompliantGroup = $inComp
      DeviceCount        = $devs.Count
      HasRegisteredDevices = $devs.Count -gt 0
    }

    $useCount = [Math]::Min($devs.Count, $MaxDevices)
    for ($i=0; $i -lt $useCount; $i++) {
      $d = $devs[$i]; $n = $i+1
      $rec["Device${n}_Id"]               = $d.Id
      $rec["Device${n}_Name"]             = $d.DeviceName
      $rec["Device${n}_OS"]               = "$($d.OperatingSystem) $($d.OsVersion)"
      $rec["Device${n}_IsPrimaryUser"]    = $d.IsPrimaryUser
      $rec["Device${n}_IsCompliant"]      = $d.IsCompliant
      $rec["Device${n}_ComplianceState"]  = $d.ComplianceState
      $rec["Device${n}_LastSync"]         = $d.LastSyncDateTime
      $rec["Device${n}_EnrolledDate"]     = $d.EnrolledDateTime
    }
    for ($i=$useCount; $i -lt $MaxDevices; $i++) {
      $n = $i+1
      $rec["Device${n}_Id"]               = ""
      $rec["Device${n}_Name"]             = ""
      $rec["Device${n}_OS"]               = ""
      $rec["Device${n}_IsPrimaryUser"]    = ""
      $rec["Device${n}_IsCompliant"]      = ""
      $rec["Device${n}_ComplianceState"]  = ""
      $rec["Device${n}_LastSync"]         = ""
      $rec["Device${n}_EnrolledDate"]     = ""
    }
    $allUserRecords.Add([PSCustomObject]$rec)
  }
} catch {
  Write-Error "Failed processing 'All Users' group: $($_.Exception.Message)"
}

# Export Intune audit
if ($allUserRecords.Count -gt 0) {
  Write-Host "`nExporting $($allUserRecords.Count) records to $OutputFile..." `
    -ForegroundColor Green
  try {
    $allUserRecords |
      Sort-Object -Property IsInCompliantGroup -Descending |
      Export-Csv -Path $OutputFile -NoTypeInformation -Encoding UTF8
    Write-Host "Intune audit at $OutputFile" -ForegroundColor Green
  } catch {
    Write-Error "Failed to export Intune audit: $($_.Exception.Message)"
  }
} else {
  Write-Warning "No Intune audit records to export."
}

Write-Host "`nScript finished."
