
# Connect if not already
  Connect-MgGraph -Scopes "User.Read.All","Group.Read.All" -NoWelcome

# 1) Prompt for UPN or objectId
$userInput = Read-Host "Enter user's UPN or object ID"
$usertoadd = read-host "Enter the user to match permsions with"
# 2) Resolve to user object to get the actual Id
try {
  $user = Get-MgUser `
            -UserId $userInput `
            -Property DisplayName,Id `
} catch {
  Write-Error "User not found or you lack permissions: $userInput"
  return
}
$userId = $user.Id
Write-Host "Resolved user '$($user.DisplayName)' → Id: $userId"

# 3) Fetch all directory-objects the user is a member of
$memberships = Get-MgUserMemberOf -UserId $userId | select-object id 

foreach ($membership in $memberships) {
  $groupId = $membership.Id
  $groupName = get-mggroup -GroupId $groupId -Property DisplayName | select-object -ExpandProperty DisplayName 
  $mailEnabled = get-mggroup -GroupId $groupId -Property MailEnabled | select-object -ExpandProperty MailEnabled
  $securityEnabled = get-mggroup -GroupId $groupId -Property SecurityEnabled | select-object -ExpandProperty SecurityEnabled
  new-mgggroupmember -GroupId $membership.Id -UserId $usertoadd
  Write-Host "Group: $groupName (Id: $groupId, Mail Enabled: $mailEnabled, Security Enabled: $securityEnabled)"
}

Write-Host $groupname
