<#
.SYNOPSIS
  Export all folders a given user has permission to across one or more sites.

.PARAMETER Sites
  One or more site-collection URLs to scan.

.PARAMETER User
  The user principal name (UPN) to check permissions for.

.PARAMETER OutputFile
  Path to the CSV you want to generate. Defaults to
  "SPPermissions_<User>_<timestamp>.csv".

.EXAMPLE
  .\Export-SPUserPermissions.ps1 `
    -Sites https://contoso.sharepoint.com/sites/TeamSite `
    -User alice@contoso.com
#>

param(
  [Parameter(Mandatory)][string[]] $Sites,
  [Parameter(Mandatory)][string]   $User,
  [string]                         $OutputFile =
  "SPPermissions_${($User -replace '[^A-Za-z0-9]','_')}_$(Get-Date -f 'yyyyMMdd_HHmmss').csv"
)

# require PnP.PowerShell
if(-not (Get-Module -ListAvailable -Name PnP.PowerShell))
{
  Write-Error "Please Install-Module PnP.PowerShell first."
  return
}

# connect once
try
{
  Write-Host "Connecting to SharePoint…" -ForegroundColor Cyan
  Connect-PnPOnline -Url $Sites[0] -Interactive | Out-Null
} catch
{
  Write-Error "Connect-PnPOnline failed: $($_.Exception.Message)"
  return
}

# helper to test group membership
function Test-UserInSPGroup
{
  param($Group, $UserLogin)
  $members = Get-PnPGroupMembers -Identity $Group.Title
  return $members | Where-Object { $_.LoginName -eq $UserLogin }
}

$results = [System.Collections.Generic.List[PSObject]]::new()

foreach($site in $Sites)
{
  Write-Host "Scanning site: $site" -ForegroundColor Yellow
  try
  {
    # set context to this site
    Connect-PnPOnline -Url $site -Interactive | Out-Null
  } catch
  {
    Write-Warning "  Cannot connect to $site $($_.Exception.Message)"
    continue
  }

  # get root web + all subwebs
  $rootWeb = Get-PnPWeb -Includes Url, Title
  $allWebs = @($rootWeb) + (Get-PnPSubWebs -Recurse -Includes Url, Title)

  foreach($web in $allWebs)
  {
    Write-Host "  Web: $($web.Url)" -ForegroundColor DarkCyan
    # switch context
    Set-PnPContext -Web $web

    # get lists (skip hidden & no-permission)
    $lists = Get-PnPList -Includes Title, RootFolder, Hidden |
      Where-Object { -not $_.Hidden }

    foreach($list in $lists)
    {
      Write-Host "    List: $($list.Title)" -NoNewline
      # get all folders via recursive CAML
      $q = "<View Scope='RecursiveAll'><Query></Query>
            <ViewFields><FieldRef Name='FileRef'/><FieldRef Name='FileDirRef'/>
            <FieldRef Name='FileLeafRef'/><FieldRef Name='FileSystemObjectType'/>
            <FieldRef Name='ID'/></ViewFields></View>"
      $items = Get-PnPListItem -List $list -Query $q
      $folders = $items | Where-Object { $_.FieldValues.FileSystemObjectType -eq 1 }
      Write-Host " → $($folders.Count) folders"

      foreach($fld in $folders)
      {
        # check if this folder has unique perms
        $li = $fld
        # load HasUniqueRoleAssignments
        $ctx = Get-PnPContext
        $ctx.Load($li, "HasUniqueRoleAssignments")
        $ctx.ExecuteQuery()
        if(-not $li.HasUniqueRoleAssignments)
        { continue 
        }

        # get the assignments
        $ras = Get-PnPRoleAssignment -List $list -ListItem $li

        # examine each RA
        foreach($ra in $ras)
        {
          $principal = $ra.Principal
          $hasAccess = $false

          # direct user?
          if($principal.LoginName -eq $User)
          {
            $hasAccess = $true
          }
          # or via SP group?
          elseif($principal.PrincipalType -eq "SharePointGroup")
          {
            if(Test-UserInSPGroup -Group $principal -UserLogin $User)
            {
              $hasAccess = $true
            }
          }

          if($hasAccess)
          {
            # collect role names
            $roles = $ra.RoleDefinitionBindings | ForEach-Object { $_.Name } -join "; "

            $results.Add([PSCustomObject]@{
                SiteUrl      = $site
                WebUrl       = $web.Url
                ListTitle    = $list.Title
                FolderUrl    = $fld.FieldValues.FileRef
                RoleSource   = $principal.Title
                RoleType     = $principal.PrincipalType
                Roles        = $roles
                Inherited    = $false
              })
          }
        }
      }
    }
  }
}

# export
if($results.Count -gt 0)
{
  Write-Host "Exporting $($results.Count) entries to $OutputFile" -ForegroundColor Green
  $results | Export-Csv -Path $OutputFile -NoTypeInformation -Encoding UTF8
  Write-Host "Done." -ForegroundColor Green
} else
{
  Write-Warning "No unique folder permissions found for $User."
}

Disconnect-PnPOnline

