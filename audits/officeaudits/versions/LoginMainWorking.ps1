# TODO
# add mfa checking
# Fix license issue
# sort users by most likely to need changes
# Connections
Connect-MgGraph -Scopes "User.Read.All", "AuditLog.Read.All" -NoWelcome
Connect-ExchangeOnline
# Get Dates for use in main loop
$CurrentDate = Get-Date
$OneMonthAgo = $CurrentDate.AddMonths(-1)
# Get all subscribed SKUs once
$SubscribedSkus = Get-MgSubscribedSku
# Function to get the last sign-in date
function Get-LastSignInDate
{
  param (
    [Microsoft.Graph.PowerShell.Models.MicrosoftGraphUser]$User
  )
  $User = Get-MgUser -UserId $User.Id -Property "signInActivity"

  $LastSignInDate = $User.signInActivity.lastSignInDateTime

  if ([string]::IsNullOrEmpty($LastSignInDate))
  {
    $LastSignInDate = "Never"
  } else
  {
    $LastSignInDate = [datetime]$LastSignInDate
  }

  return $LastSignInDate
}

# Function to get the last sent message date
function Get-LastSentMessageDate
{
  param (
    [string]$MailId
  )
  
  # Initialize $LastSentTime
  $LastSentTime = $null

  # Check if the user has a mailbox
  $HasMailbox = Get-Recipient -Identity $MailId -ErrorAction SilentlyContinue

  if ($null -ne $HasMailbox)
  {
    try
    {
      # Use Get-MailboxFolderStatistics to get the Sent Items folder statistics
      $MailboxStats = Get-MailboxFolderStatistics -Identity $MailId -FolderScope SentItems -IncludeOldestAndNewestItems -resultsize 5 -ErrorAction Stop

      # Get the 'Sent Items' folder
      $SentItemsFolder = $MailboxStats | Where-Object { $_.FolderType -eq 'SentItems' }

      if ($null -ne $SentItemsFolder)
      {
        $LastSentTime = $SentItemsFolder.NewestItemReceivedDate

        if ($null -eq $LastSentTime)
        {
          $LastSentTime = "No Sent Emails"
        }
      } else
      {
        $LastSentTime = "No Sent Items Folder"
      }
    } catch
    {
      Write-Host "Error accessing mailbox for '$MailId': $($_.Exception.Message)"
      $LastSentTime = "Error"
    }
  } else
  {
    Write-Host "User $MailId does not have a mailbox."
    $LastSentTime = "No Mailbox"
  }

  return $LastSentTime
}

# Function to get assigned licenses
function Get-AssignedLicenses
{
  param (
    [Microsoft.Graph.PowerShell.Models.MicrosoftGraphUser]$User,
    [Hashtable]$SkuMap
  )
  # Build a hashtable of SkuId to SkuPartNumber
  $SkuMap = @{}
  foreach ($Sku in $SubscribedSkus)
  {
    $SkuMap[$Sku.SkuId] = $Sku.SkuPartNumber
  }

  # Define AssignedLicenses
  $AssignedLicenses = $User.AssignedLicenses

  # Extract the SKU IDs from the assigned licenses
  $skuIds = $AssignedLicenses | Select-Object -ExpandProperty SkuId

  # Map SKU IDs to SKU Part Numbers using the hashtable
  $skuPartNumbers = $skuIds | ForEach-Object {
    $skuId = $_
    $skuPartNumber = $SkuMap[$skuId]
    if ($null -eq $skuPartNumber)
    {
      $skuPartNumber = $skuId  # Use the SKU ID if Part Number not found
    }
    $skuPartNumber
  }
  return ($skuPartNumbers -join "; ")
}

# Initialize an array to hold the results
$Results = @()

# Get all users
$Users = Get-MgUser -all -Select "id,displayName,userPrincipalName,signInActivity,assignedLicenses" | Select-Object -first 10


# Main foreach loop to get user data
foreach ($User in $Users)
{
  Write-Host "Processing user: $($User.DisplayName) ($($User.UserPrincipalName))"
  
  # Get the assigned licenses for the user
  $Licenses = Get-AssignedLicenses -User $User -SkuMap $SkuMap

  # Get Last Sign-In Date
  $LastSignInDate = Get-LastSignInDate -User $User

  # Process only users who haven't signed in for over a month
  if ($LastSignInDate -eq "Never" -or $LastSignInDate -lt $OneMonthAgo)
  {
    # Get UserPrincipalName
    $MailId = $User.UserPrincipalName

    # Get Last Sent Message Date
    $LastSentTime = Get-LastSentMessageDate -MailId $MailId

    # Create a custom object with user info
    $UserInfo = [PSCustomObject]@{
      DisplayName       = $User.DisplayName
      UserPrincipalName = $MailId
      LastSignInDate    = $LastSignInDate
      LastSentMessage   = $LastSentTime
      Licenses          = $Licenses
    }

    # Add to results
    $Results += $UserInfo
  }
}
# Export the results to a CSV file
$Results | Export-Csv -Path "InactiveUsers.csv" -NoTypeInformation

Write-Host "Report generated: InactiveUsers.csv"


