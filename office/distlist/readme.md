# Distribution List Management Script

## Overview

This script matches distribution list memberships between two users, adding UserA to all distribution lists that UserB belongs to.

## Status

⚠️ **Currently under maintenance** - Script may require updates for current Exchange Online API changes.

## Prerequisites

- Exchange Online Management PowerShell module
- Microsoft Graph PowerShell module
- Exchange Online administrator permissions

## Usage

```powershell
.\matchdistlists.ps1 -UserA "source@domain.com" -UserB "target@domain.com"
```

## Parameters

- **UserA**: Source user whose distribution list memberships will be copied
- **UserB**: Target user who will be added to the same distribution lists

## Notes

This script connects to both Exchange Online and Microsoft Graph to handle both distribution groups and security groups.

## Contact

- Author: Jonathan Costin
