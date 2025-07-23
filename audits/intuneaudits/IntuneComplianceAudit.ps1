<#
.SYNOPSIS
Audits Microsoft Intune environment for device compliance using recommended Graph cmdlets.
.DESCRIPTION
This script queries Microsoft Graph using Get-MgDeviceManagementManagedDevice
to get information about users and their device compliance status, focusing
on primary and enrolled devices. Each user appears once with devices
expanding horizontally to the right.
.PARAMETER AllUsersGroupId
The ID of the group containing all users.
.PARAMETER CompliantUsersGroupId
The ID of the group containing users restricted to compliant devices.
.PARAMETER MaxDevices
Maximum number of devices to report per user (default: 10).
.EXAMPLE
.\IntuneComplianceAudit.ps1 -AllUsersGroupId "12345678-1234-1234-1234-123456789012" -CompliantUsersGroupId "87654321-4321-4321-4321-210987654321"
#>
param (
  [Parameter(Mandatory = $true)]
  [string]$AllUsersGroupId,

  [Parameter(Mandatory = $true)]
  [string]$CompliantUsersGroupId,

  [Parameter(Mandatory = $false)]
  [int]$MaxDevices = 10,

  [Parameter(Mandatory = $false)]
  [string]$OutputFile = "IntuneComplianceAudit_$(Get-Date -Format 'yyyyMMdd').csv"
)

# --- Module Checks and Installation ---
# Ensure Microsoft Graph module is available
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.DeviceManagement))
{
  Write-Host "Microsoft Graph DeviceManagement module not found. Installing..."
  try
  {
    Install-Module Microsoft.Graph.DeviceManagement -Scope CurrentUser -Force -AllowClobber
  } catch
  {
    Write-Error "Failed to install Microsoft.Graph.DeviceManagement module. Please install manually."
    return
  }
}
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Groups))
{
  Write-Host "Microsoft Graph Groups module not found. Installing..."
  try
  {
    Install-Module Microsoft.Graph.Groups -Scope CurrentUser -Force -AllowClobber
  } catch
  {
    Write-Error "Failed to install Microsoft.Graph.Groups module. Please install manually."
    return
  }
}
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Users))
{
  Write-Host "Microsoft Graph Users module not found. Installing..."
  try
  {
    Install-Module Microsoft.Graph.Users -Scope CurrentUser -Force -AllowClobber
  } catch
  {
    Write-Error "Failed to install Microsoft.Graph.Users module. Please install manually."
    return
  }
}

# --- Module Imports ---
Import-Module Microsoft.Graph.Users
Import-Module Microsoft.Graph.Groups
Import-Module Microsoft.Graph.DeviceManagement

# --- Graph Connection ---
$requiredScopes = "User.Read.All", "GroupMember.Read.All", "DeviceManagementManagedDevices.Read.All"
try
{
  Connect-MgGraph -Scopes $requiredScopes
  Write-Host "Successfully connected to Microsoft Graph." -ForegroundColor Green
} catch
{
  Write-Error "Failed to connect to Microsoft Graph. Error: $($_.Exception.Message)"
  return
}
# --- Tenant Name & Dynamic OutputFile Name ---
try
{
  # Usually there's exactly one organization object
  $org = Get-MgOrganization -ErrorAction Stop
  $tenantName = $org.DisplayName
} catch
{
  Write-Warning "Could not retrieve tenant name: $($_.Exception.Message)"
  $tenantName = "UnknownTenant"
}

# replace any non-alphanumeric with underscores
$safeTenant = $tenantName -replace '[^A-Za-z0-9\-]', '_'

# timestamp for uniqueness
$ts = Get-Date -Format 'yyyyMMdd_HHmmss'

# only override default if user did NOT explicitly supply -OutputFile
if (-not $PSBoundParameters.ContainsKey('OutputFile'))
{
  $OutputFile = "IntuneComplianceAudit_${safeTenant}_${ts}.csv"
}

Write-Host "Results will be exported to: $OutputFile" -ForegroundColor Cyan


# --- Compliant User Hash Table ---
$compliantUsersHash = @{}
Write-Host "Building list of users in compliant group ($CompliantUsersGroupId)..."
try
{
  $compliantMembers = Get-MgGroupMember -GroupId $CompliantUsersGroupId -All -ErrorAction Stop
  foreach ($member in $compliantMembers)
  {
    if ($member.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.user')
    {
      $compliantUsersHash[$member.Id] = $true
    }
  }
  Write-Host "Found $($compliantUsersHash.Count) users in compliant group." -ForegroundColor Green
} catch
{
  Write-Error "Failed to get members for compliant group '$CompliantUsersGroupId'. Error: $($_.Exception.Message)"
}


# Function to get user's devices (primary and enrolled) using LOCAL filtering
function Get-UserPrimaryDevices
{
  param (
    [Parameter(Mandatory = $true)]
    [string]$UserId,
    [Parameter(Mandatory = $true)]
    [string]$UserPrincipalName
  )

  # Use a dictionary to store unique devices found for this specific user
  $userSpecificDevices = [System.Collections.Generic.Dictionary[string,PSObject]]::new()
  $allTenantDevices = $null # Variable to hold all devices

  try
  {
    # Get ALL devices
    $allTenantDevices = Get-MgDeviceManagementManagedDevice -All -ErrorAction Stop

    if ($null -eq $allTenantDevices -or $allTenantDevices.Count -eq 0)
    {
      return @() # Return empty if no devices found at all
    }

    # Filter for user's devices
    foreach ($device in $allTenantDevices)
    {
      $isPrimary = $false
      $isEnroller = $false

      # Check if current user is the primary user
      if ($device.UserId -eq $UserId)
      {
        $isPrimary = $true
      }

      # Check if current user is the enroller
      if ($device.EnrolledByUserId -eq $UserId)
      {
        $isEnroller = $true
      }

      # If the user has either relationship with this device...
      if ($isPrimary -or $isEnroller)
      {
        # Check if device is already added to this user's list
        if ($userSpecificDevices.ContainsKey($device.Id))
        {
          # Update existing entry if necessary (e.g., was added as enroller, now found as primary)
          if ($isPrimary)
          { 
            $userSpecificDevices[$device.Id].IsPrimaryUser = $true 
          }
          if ($isEnroller)
          { 
            $userSpecificDevices[$device.Id].IsEnroller = $true 
          }
        } else
        {
          # Check the compliance state directly and determine if it's compliant
          $isDeviceCompliant = $false
          
          # Try multiple potential ways to determine compliance
          if ($device.ComplianceState -eq "compliant")
          {
            $isDeviceCompliant = $true
          } elseif ($device.ComplianceState -eq "Compliant")
          {
            $isDeviceCompliant = $true
          }
          
          # Add new device entry for this user
          $deviceObj = [PSCustomObject]@{
            Id = $device.Id
            DeviceName = $device.DeviceName
            OperatingSystem = $device.OperatingSystem
            OsVersion = $device.OsVersion
            ComplianceState = $device.ComplianceState
            IsCompliant = $isDeviceCompliant
            LastSyncDateTime = $device.LastSyncDateTime
            EnrolledDateTime = $device.EnrolledDateTime
            IsPrimaryUser = $isPrimary
            IsEnroller = $isEnroller
          }
          $userSpecificDevices.Add($device.Id, $deviceObj)
        }
      }
    } # End foreach device in allTenantDevices

    return $userSpecificDevices.Values

  } catch
  {
    Write-Warning "Error during device query/filtering for user $UserPrincipalName (ID: $UserId). Error: $($_.Exception.Message)"
    # If the error was getting all devices, $allTenantDevices might be null
    if ($null -ne $allTenantDevices)
    {
      Write-Warning "Processing stopped after retrieving $($allTenantDevices.Count) tenant devices."
    } else
    {
      Write-Warning "Processing stopped, potentially before or during retrieval of all tenant devices."
    }
    return @() # Return empty array on error
  }
}

# --- Main User Processing Loop ---
$allUserRecords = [System.Collections.Generic.List[PSObject]]::new()
Write-Host "Processing users from 'All Users' group ($AllUsersGroupId)..."
try
{
  $allUsersGroupMembers = Get-MgGroupMember -GroupId $AllUsersGroupId -All -ErrorAction Stop
  # Filter group members to only include users before counting
  $userMembers = $allUsersGroupMembers | Where-Object { $_.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.user' }
  $totalUsers = $userMembers.Count
  $userCounter = 0

  # Iterate only over user members
  foreach ($member in $userMembers)
  {
    # No need to check type again, already filtered
    $user = Get-MgUser -UserId $member.Id -Property Id, UserPrincipalName, DisplayName -ErrorAction SilentlyContinue
    if (-not $user)
    {
      Write-Warning "Could not retrieve details for user ID $($member.Id)"
      continue
    }

    $userCounter++
    $userId = $user.Id
    $userPrincipalName = $user.UserPrincipalName
    $displayName = $user.DisplayName

    Write-Progress -Activity "Processing Users" -Status "User $userCounter/$totalUsers ($userPrincipalName)" -PercentComplete (($userCounter / $totalUsers) * 100)

    # Check if user is in compliant group
    $isInCompliantGroup = $compliantUsersHash.ContainsKey($userId)

    # Get user's primary/enrolled devices
    $devices = Get-UserPrimaryDevices -UserId $userId -UserPrincipalName $userPrincipalName

    # Create the base user record using an ordered dictionary
    $userRecord = [ordered]@{
      UserPrincipalName = $userPrincipalName
      DisplayName = $displayName
      IsInCompliantGroup = $isInCompliantGroup
      DeviceCount = $devices.Count # Count devices returned specifically for this user
      HasRegisteredDevices = $devices.Count -gt 0
    }

    # Add device properties horizontally, limited by MaxDevices
    $deviceOutputCount = [Math]::Min($devices.Count, $MaxDevices)

    for ($deviceIndex = 0; $deviceIndex -lt $deviceOutputCount; $deviceIndex++)
    {
      $device = $devices[$deviceIndex]
      $deviceNumber = $deviceIndex + 1

      $userRecord["Device${deviceNumber}_Id"] = $device.Id
      $userRecord["Device${deviceNumber}_Name"] = $device.DeviceName
      $userRecord["Device${deviceNumber}_OS"] = "$($device.OperatingSystem) $($device.OsVersion)"
      $userRecord["Device${deviceNumber}_IsPrimaryUser"] = $device.IsPrimaryUser
      
      # Use the already determined compliance value
      $userRecord["Device${deviceNumber}_IsCompliant"] = $device.IsCompliant
      
      $userRecord["Device${deviceNumber}_ComplianceState"] = $device.ComplianceState
      $userRecord["Device${deviceNumber}_LastSync"] = $device.LastSyncDateTime
      $userRecord["Device${deviceNumber}_EnrolledDate"] = $device.EnrolledDateTime
    }

    # Add placeholder columns
    for ($deviceIndex = $deviceOutputCount; $deviceIndex -lt $MaxDevices; $deviceIndex++)
    {
      $deviceNumber = $deviceIndex + 1
      $userRecord["Device${deviceNumber}_Id"] = ""
      $userRecord["Device${deviceNumber}_Name"] = ""
      $userRecord["Device${deviceNumber}_OS"] = ""
      $userRecord["Device${deviceNumber}_IsPrimaryUser"] = ""
      $userRecord["Device${deviceNumber}_IsCompliant"] = ""
      $userRecord["Device${deviceNumber}_ComplianceState"] = ""
      $userRecord["Device${deviceNumber}_LastSync"] = ""
      $userRecord["Device${deviceNumber}_EnrolledDate"] = ""
    }

    # Add the complete user record to the list
    $allUserRecords.Add([PSCustomObject]$userRecord)
  }
} catch
{
  Write-Error "Failed to process members for 'All Users' group '$AllUsersGroupId'. Error: $($_.Exception.Message)"
}


# --- CSV Export (after building $allUserRecords) ---
if ($allUserRecords.Count -gt 0)
{
  Write-Host "`nExporting $($allUserRecords.Count) user records to $OutputFile..." `
    -ForegroundColor Green
  try
  {
    # Sort so that compliant‐group members come first
    $allUserRecords |
      Sort-Object -Property IsInCompliantGroup -Descending |
      Export-Csv -Path $OutputFile `
        -NoTypeInformation `
        -Encoding UTF8 `
        -ErrorAction Stop
    Write-Host "Export complete." -ForegroundColor Green
  } catch
  {
    Write-Error "Failed to export results to '$OutputFile'. Error: $($_.Exception.Message)"
  }
} else
{
  Write-Warning "No user records were generated to export."
}
# --- Graph Disconnect ---
Write-Host "Disconnecting from Microsoft Graph..."
Disconnect-MgGraph

Write-Host "Script finished."


