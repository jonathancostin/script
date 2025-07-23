# Mailbox Archive Policy Manager

## Overview
This PowerShell script automates the configuration of Exchange Online mailbox archiving policies. It allows administrators to create or select archive retention tags, configure retention policies, enable archive mailboxes, and apply policies to specified users.

## Files
- `setmailboxarchive.ps1` - Main script for configuring mailbox archive policies

## Requirements
- PowerShell 5.1 or later
- ExchangeOnlineManagement module
- Exchange Online administrator permissions

## Installation
```powershell
Install-Module -Name ExchangeOnlineManagement -Force
```

## Usage
```powershell
.\setmailboxarchive.ps1
```

The script runs interactively and will prompt for all necessary information.

## Features
- **Interactive Configuration**: User-friendly prompts for all settings
- **Archive Tag Management**: Create new or reuse existing MoveToArchive tags
- **Policy Management**: Automatically creates or reuses retention policies
- **Archive Enablement**: Enables archive mailboxes if not already enabled
- **Batch Processing**: Configure multiple mailboxes in a single run
- **Policy Application**: Applies retention policies and triggers Managed Folder Assistant
- **Verification**: Displays final configuration for confirmation

## Process Flow

### Step 1: Archive Tag Selection
Choose between:
1. **Use existing MoveToArchive tag** - Select from available tags
2. **Create new MoveToArchive tag** - Specify custom retention period in days

### Step 2: Retention Policy Configuration
- Automatically finds or creates a retention policy containing the selected tag
- Handles multiple policies linking to the same tag
- Creates new policy if none exist

### Step 3: Mailbox Configuration
- Prompts for comma-separated list of mailbox identities
- Enables archive mailbox if not already enabled
- Applies the retention policy
- Triggers Managed Folder Assistant for immediate processing

### Step 4: Verification
- Displays final configuration for each processed mailbox
- Shows retention policy, archive status, and associated tags

## Example Session
```powershell
PS> .\setmailboxarchive.ps1

Connecting to Exchange Online…

Choose an option:
  [1] Use existing MoveToArchive tag
  [2] Create new MoveToArchive tag for custom days
Enter 1 or 2: 2
Enter retention period in days: 365

Creating new MoveToArchive tag 'CustomArchive_365d' (365 days)…
Created tag.
Selected archive tag: CustomArchive_365d

Creating new policy 'Policy_CustomArchive_365d'…
Created policy.

Enter mailbox identities (comma-separated): john.doe@company.com, jane.smith@company.com

Processing john.doe@company.com…
  Archive already enabled.
  Assigning policy 'Policy_CustomArchive_365d'… Done
  Running ManagedFolderAssistant… Done

Processing jane.smith@company.com…
  Enabling archive… Done
  Assigning policy 'Policy_CustomArchive_365d'… Done
  Running ManagedFolderAssistant… Done
```

## Archive Tag Types
- **MoveToArchive**: Moves items to the archive mailbox after specified days
- **Custom Tags**: Created with specific retention periods (e.g., 30, 90, 365 days)
- **Existing Tags**: Reuse previously created organizational tags

## Policy Management
- **Automatic Creation**: Creates policies when none exist for the selected tag
- **Policy Reuse**: Uses existing policies when available
- **Multiple Policies**: Handles cases where multiple policies contain the same tag

## Verification Output
```
John Doe
  RetentionPolicy: Policy_CustomArchive_365d
  ArchiveStatus:   Active
  TagsInPolicy:    CustomArchive_365d

Jane Smith  
  RetentionPolicy: Policy_CustomArchive_365d
  ArchiveStatus:   Active
  TagsInPolicy:    CustomArchive_365d
```

## Error Handling
- **Invalid Selections**: Validates menu choices and user input
- **Missing Dependencies**: Checks for required PowerShell modules
- **Authentication Issues**: Handles connection failures gracefully
- **Mailbox Errors**: Reports issues with individual mailboxes but continues processing

## Security Notes
- Requires Exchange Online administrator privileges
- Uses modern authentication with MFA support  
- Automatically disconnects from Exchange Online when complete
- Changes take effect immediately via Managed Folder Assistant

## Best Practices
- Test with a small number of mailboxes first
- Document retention periods for compliance requirements
- Monitor archive mailbox usage after policy application
- Consider organizational retention policies before creating custom tags
