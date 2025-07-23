# SharePoint User Permissions Report

## Overview
This PowerShell script generates comprehensive reports of SharePoint folder permissions for specific users across one or more SharePoint sites. It identifies all folders where a user has direct or inherited permissions and exports the results to CSV format.

## Files
- `report.ps1` - Main script for generating SharePoint permission reports

## Requirements
- PowerShell 5.1 or later
- PnP.PowerShell module
- SharePoint Online administrator permissions or site collection administrator rights

## Installation
```powershell
Install-Module -Name PnP.PowerShell -Force
```

## Usage
```powershell
.\report.ps1 -Sites "https://contoso.sharepoint.com/sites/TeamSite" -User "alice@contoso.com"
```

### Parameters
- **Sites** (Mandatory): One or more SharePoint site collection URLs to scan
- **User** (Mandatory): User Principal Name (UPN) to check permissions for  
- **OutputFile** (Optional): Custom path for CSV output file

### Multiple Sites Example
```powershell
.\report.ps1 -Sites @("https://contoso.sharepoint.com/sites/TeamSite", "https://contoso.sharepoint.com/sites/ProjectSite") -User "alice@contoso.com"
```

## Features
- **Multi-Site Support**: Scan multiple SharePoint sites in a single execution
- **Recursive Scanning**: Examines all webs and subwebs within each site
- **Folder-Level Permissions**: Focuses on folders with unique permissions
- **Group Membership Detection**: Identifies permissions granted through SharePoint groups
- **Direct Permission Detection**: Finds directly assigned user permissions
- **Comprehensive Output**: Detailed CSV report with all permission details

## Process Flow
1. **Authentication**: Connects to SharePoint Online with interactive authentication
2. **Site Scanning**: Iterates through each specified site collection
3. **Web Discovery**: Finds root web and all subwebs recursively
4. **List Enumeration**: Examines all non-hidden lists in each web
5. **Folder Analysis**: Identifies folders with unique permissions
6. **Permission Check**: Tests user access through direct assignment or group membership
7. **Report Generation**: Exports findings to CSV format

## Output
The script generates a timestamped CSV file with the following columns:
- **SiteUrl** - The SharePoint site collection URL
- **WebUrl** - The specific web/subsite URL
- **ListTitle** - Name of the document library or list
- **FolderUrl** - Full server-relative URL of the folder
- **RoleSource** - Name of the security principal granting access
- **RoleType** - Type of principal (User, SharePointGroup, etc.)
- **Roles** - Permission levels assigned (e.g., "Full Control; Edit")
- **Inherited** - Whether permissions are inherited (always false for unique permissions)

## Example Output
```csv
SiteUrl,WebUrl,ListTitle,FolderUrl,RoleSource,RoleType,Roles,Inherited
https://contoso.sharepoint.com/sites/TeamSite,https://contoso.sharepoint.com/sites/TeamSite,Documents,/sites/TeamSite/Shared Documents/Project Files,TeamSite Members,SharePointGroup,Edit,false
```

## File Naming Convention
Default output filename format: `SPPermissions_<sanitized_username>_<timestamp>.csv`

Example: `SPPermissions_alice_contoso_com_20240123_143022.csv`

## Error Handling
- **Connection Failures**: Reports sites that cannot be accessed
- **Permission Errors**: Continues processing other items if specific folders fail
- **Module Dependencies**: Validates PnP.PowerShell module availability

## Security Considerations
- Requires appropriate SharePoint permissions to read site structures and permissions
- Uses interactive authentication supporting MFA
- Automatically disconnects from SharePoint when complete
- Only reports on folders with unique (non-inherited) permissions

## Performance Notes
- Processing time depends on number of sites, webs, lists, and folders
- Large sites with many unique permissions may take considerable time
- Progress indicators show current site and web being processed
