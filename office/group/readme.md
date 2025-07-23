# Group Management Script

## Overview

This script manages group memberships by adding a user to all groups that another user belongs to.

## Status

⚠️ **Currently under maintenance** - Script requires updates for current Microsoft Graph API implementation.

## Prerequisites

- Microsoft Graph PowerShell module
- Microsoft Graph permissions:
  - User.Read.All
  - Group.Read.All
  - GroupMember.ReadWrite.All

## Usage

```powershell
.\group.ps1
```

The script will prompt for:
- User UPN or object ID (source user)
- User to add (target user)

## Functionality

1. Resolves user objects from input
2. Retrieves all group memberships for the source user
3. Adds the target user to each group
4. Reports on mail-enabled and security-enabled group types

## Notes

Handles both security groups and mail-enabled groups through Microsoft Graph API.

## Contact

- Author: Jonathan Costin
- Email: jonathanc@7layerit.com
