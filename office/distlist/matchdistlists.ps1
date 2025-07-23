
[CmdletBinding()]
param(
  [Parameter(Mandatory)]
  [string] $UserA,

  [Parameter(Mandatory)]
  [string] $UserB
)



# 2) Connect to Exchange Online (for DLs)
Write-Host "`nConnecting to Exchange Online…"
Connect-ExchangeOnline
# 3) Connect to Microsoft Graph (for security groups)
$scopes = "Group.ReadWrite.All","User.Read.All"
Write-Host "Connecting to Microsoft Graph…"
Connect-MgGraph -Scopes $scopes

# 4) Resolve both users via Graph
$userAObj = Get-MgUser -UserId $UserA -ErrorAction Stop
$userBObj = Get-MgUser -UserId $UserB -ErrorAction Stop

Write-Host "`nResolved Users:"
Write-Host " • UserA: $($userAObj.DisplayName) ($($userAObj.Id))"
Write-Host " • UserB: $($userBObj.DisplayName) ($($userBObj.Id))"

# 5) DISTRIBUTION GROUPS (Exchange Online)
Write-Host "`nRetrieving distribution lists for $UserB…" -NoNewline
$allDLs = Get-DistributionGroup -ResultSize Unlimited
# Filter to those where B is a member
$dlList = foreach($dl in $allDLs)
{
  try
  {
    $members = Get-DistributionGroupMember -Identity $dl.Identity `
      -ResultSize Unlimited -ErrorAction Stop
    if ($members.PrimarySmtpAddress -contains $UserB)
    {
      $dl
    }
  } catch
  { 
  }
}
Write-Host " found $($dlList.Count) DL(s)."

foreach ($dl in $dlList)
{
  Write-Host " ��� Adding $UserA to DL '$($dl.DisplayName)'…" -NoNewline
  try
  {
    Add-DistributionGroupMember -Identity $dl.Identity `
      -Member $UserA -ErrorAction Stop
    Write-Host " OK"
  } catch
  {
    $msg = $_.Exception.Message
    if ($msg -match "already a member")
    {
      Write-Host " already a member, skipping"
    } else
    {
      Write-Host " FAILED: $msg"
    }
  }
}
