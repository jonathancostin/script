#Requires -Modules ExchangeOnlineManagement

# --- Configuration ---
$TargetUserIdentity = Read-Host "enter email of user to check" # UPN or Alias of the user
$CsvOutputPath = "CalendarPermissionsReport.csv" # Path for the CSV export
# --- End Configuration ---

# Connect to Exchange Online (prompts for credentials if needed)
Write-Host "Connecting to Exchange Online..."
Connect-ExchangeOnline

# Get all user mailboxes
Write-Host "Retrieving mailboxes..."
$AllMailboxes = Get-Mailbox -ResultSize Unlimited -RecipientTypeDetails UserMailbox

$PermissionResults = @()

Write-Host "Checking permissions for '$TargetUserIdentity'..."
# Iterate through each mailbox
foreach ($Mailbox in $AllMailboxes)
{
  $MailboxUPN = $Mailbox.UserPrincipalName
  $CalendarIdentity = $MailboxUPN + ":\Calendar"
  $AccessLevel = "None" # Default if no permissions found

  try
  {
    # Get permissions for the default calendar folder for the specific user
    $Permissions = Get-MailboxFolderPermission -Identity $CalendarIdentity -User $TargetUserIdentity -ErrorAction SilentlyContinue

    # Check if a permission entry was returned for the target user
    if ($Permissions)
    {
      # AccessRights is an array, join if multiple roles (unlikely for single user query)
      $AccessLevel = $Permissions.AccessRights -join ', '
    }
  } catch
  {
    # Log errors for specific mailboxes if needed, otherwise continue
    # Could indicate issues accessing the mailbox/calendar itself
    Write-Warning "Could not check permissions for '$MailboxUPN'. Error: $($_.Exception.Message)"
    $AccessLevel = "Error Checking"
  }

  # Add result to the collection
  $PermissionResults += [PSCustomObject]@{
    Mailbox     = $MailboxUPN
    AccessLevel = $AccessLevel
  }
}# Export the results to a CSV file
Write-Host "Exporting results to '$CsvOutputPath'..."
$PermissionResults | Export-Csv -Path $CsvOutputPath -NoTypeInformation

# Disconnect from Exchange Online
Write-Host "Disconnecting from Exchange Online..."
Disconnect-ExchangeOnline -Confirm:$false

Write-Host "Script completed."

