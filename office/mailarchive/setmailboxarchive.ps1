# ------------------------------------------------------------
# Set-ArchivePolicy.ps1
#   • Connects to Exchange Online
#   • Lets you pick or create a MoveToArchive tag (custom days)
#   • Reuses or creates a retention policy containing that tag
#   • Enables archive mailbox if needed
#   • Assigns policy & fires ManagedFolderAssistant
#   • Verifies status
# ------------------------------------------------------------

# 1. Connect
Write-Host "Connecting to Exchange Online…" -ForegroundColor Cyan
Connect-ExchangeOnline -ShowBanner:$false

# 2. Choose or create an archive tag
Write-Host "`nChoose an option:" -ForegroundColor Cyan
Write-Host "  [1] Use existing MoveToArchive tag"
Write-Host "  [2] Create new MoveToArchive tag for custom days"
[int]$mode = Read-Host "Enter 1 or 2"
if ($mode -eq 1)
{
  # 2a. List existing MoveToArchive tags
  $tags = Get-RetentionPolicyTag -Type All |
    Where-Object RetentionAction -eq 'MoveToArchive' |
    Select-Object Name,AgeLimitForRetention
  if ($tags.Count -eq 0)
  {
    Write-Error "No MoveToArchive tags found. Exiting."; exit 1
  }
  Write-Host "`nAvailable Archive Tags:" -ForegroundColor Cyan
  for ($i = 0; $i -lt $tags.Count; $i++)
  {
    $t = $tags[$i]
    Write-Host (" [{0}] {1}  ({2}d)" -f $i,$t.Name,$t.AgeLimitForRetention)
  }
  [int]$idx = Read-Host "`nEnter the index of the tag to use"
  if ($idx -lt 0 -or $idx -ge $tags.Count)
  {
    Write-Error "Invalid index. Exiting."; exit 1
  }
  $tagName = $tags[$idx].Name
} elseif ($mode -eq 2)
{
  # 2b. Create a new tag
  [int]$days = Read-Host "Enter retention period in days"
  if ($days -le 0)
  {
    Write-Error "Days must be a positive integer. Exiting."; exit 1
  }
  # sanitize name
  $tagName = "CustomArchive_${days}d"
  # check existence
  if (Get-RetentionPolicyTag -Identity $tagName -ErrorAction SilentlyContinue)
  {
    Write-Host "Tag '$tagName' already exists. Reusing it." `
      -ForegroundColor Yellow
  } else
  {
    Write-Host "Creating new MoveToArchive tag '$tagName' ($days days)…" `
      -ForegroundColor Yellow
    New-RetentionPolicyTag `
      -Name       $tagName `
      -Type       All `
      -RetentionAction MoveToArchive `
      -AgeLimitForRetention $days
    Write-Host "Created tag." -ForegroundColor Green
  }
} else
{
  Write-Error "Invalid choice. Exiting."; exit 1
}
Write-Host "Selected archive tag: $tagName`n" -ForegroundColor Green

# 3. Find or create a Retention Policy containing that tag
$existingPolicies = Get-RetentionPolicy |
  Where-Object { $_.RetentionPolicyTagLinks -contains $tagName }

if ($existingPolicies.Count -gt 1)
{
  Write-Host "Multiple policies link to '$tagName':" `
    -ForegroundColor Yellow
  for ($j = 0; $j -lt $existingPolicies.Count; $j++)
  {
    Write-Host ("  [{0}] {1}" -f $j,$existingPolicies[$j].Name)
  }
  [int]$pidx = Read-Host "Pick policy by index"
  if ($pidx -lt 0 -or $pidx -ge $existingPolicies.Count)
  {
    Write-Error "Invalid index. Exiting."; exit 1
  }
  $policyName = $existingPolicies[$pidx].Name
} elseif ($existingPolicies.Count -eq 1)
{
  $policyName = $existingPolicies[0].Name
  Write-Host "Reusing policy: $policyName" -ForegroundColor Green
} else
{
  $policyName = "Policy_$($tagName -replace '[^0-9A-Za-z]','_')"
  Write-Host "Creating new policy '$policyName'…" -ForegroundColor Yellow
  New-RetentionPolicy `
    -Name $policyName `
    -RetentionPolicyTagLinks $tagName
  Write-Host "Created policy." -ForegroundColor Green
}

# 4. Prompt for mailbox identities
$userInput = Read-Host "`nEnter mailbox identities (comma-separated)"
$users = $userInput.Split(',') |
  ForEach-Object { $_.Trim() } |
  Where-Object { $_ -ne '' }

if ($users.Count -eq 0)
{
  Write-Error "No users specified. Exiting."; exit 1
}

# 5. Process each mailbox
foreach ($u in $users)
{
  Write-Host "`nProcessing $u…" -ForegroundColor Cyan

  # a) Ensure archive is enabled
  $mb = Get-Mailbox -Identity $u -ErrorAction Stop
  if ($mb.ArchiveStatus -eq 'None')
  {
    Write-Host "  Enabling archive…" -NoNewline
    Enable-Mailbox -Identity $u -Archive
    Write-Host " Done" -ForegroundColor Green
  } else
  {
    Write-Host "  Archive already enabled." -ForegroundColor Gray
    $enableexpand = Read-Host " enable autoexpanding archive? (y/n)"
  }

  # b) Assign the retention policy
  Write-Host "  Assigning policy '$policyName'…" -NoNewline
  Set-Mailbox -Identity $u -RetentionPolicy $policyName -Confirm:$false
  Write-Host " Done" -ForegroundColor Green

  # c) Force the Managed Folder Assistant
  Write-Host "  Running ManagedFolderAssistant…" -NoNewline
  Start-ManagedFolderAssistant -Identity $u
  Write-Host " Done" -ForegroundColor Green

  if $enableexpand -eq 'y'
  {
    # d) Enable auto-expanding archive if requested
    Write-Host "  Enabling auto-expanding archive…" -NoNewline
    Enable-Mailbox -Identity $u -AutoExpandingArchive
    Write-Host " Done" -ForegroundColor Green
  } else
  {
    Write-Host "  Skipping auto-expanding archive." -ForegroundColor Gray
  }

}

# 6. Verification
Write-Host "`n— Verification —`n" -ForegroundColor Cyan
foreach ($u in $users)
{
  $mb = Get-Mailbox -Identity $u |
    Select-Object Name,RetentionPolicy,ArchiveStatus

  $tagsInPolicy = (Get-RetentionPolicy -Identity $policyName |
      Select-Object -ExpandProperty RetentionPolicyTagLinks) -join ', '

  # Build the text first
  $output = "{0}`n" +
  "  RetentionPolicy: {1}`n" +
  "  ArchiveStatus:    {2}`n" +
  "  TagsInPolicy:     {3}`n" `
    -f $mb.Name,
  $mb.RetentionPolicy,
  $mb.ArchiveStatus,
  $tagsInPolicy

  # Then write it with a color
  Write-Host $output -ForegroundColor Cyan
}

# 7. Disconnect
Disconnect-ExchangeOnline -Confirm:$false
Write-Host "All done." -ForegroundColor Cyan
write-host "Ignore the RPC Error, it still worked :)"
