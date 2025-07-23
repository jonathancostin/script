# Global Address List (GAL) Export Scripts

## Overview
This directory contains PowerShell scripts for exporting various components of the Global Address List from Exchange Online, providing administrators with comprehensive directory information in CSV format.

## Files
- `galexport.ps1` - Exports all address lists with their recipient filters
- `galusers.ps1` - Exports all users from the Default Global Address List

## Requirements
- PowerShell 5.1 or later
- ExchangeOnlineManagement module
- Exchange Online administrator permissions

## Installation
```powershell
Install-Module -Name ExchangeOnlineManagement -Force
```

## Scripts

### galexport.ps1
**Purpose**: Exports all address lists in the organization along with their recipient filters.

**Usage**:
```powershell
.\galexport.ps1
```

**Output**: Creates `~/all-addresslists.csv` with columns:
- **Name** - Address list name
- **RecipientFilter** - Filter criteria used by the address list

### galusers.ps1  
**Purpose**: Exports all users from the Default Global Address List with their basic information.

**Usage**:
```powershell
.\galusers.ps1
```

**Output**: Creates `~/gal-emails.csv` with columns:
- **Name** - Display name of the user
- **PrimarySmtpAddress** - Primary email address

## Features
- **Automated Export**: Both scripts handle the complete export process
- **CSV Format**: Results are exported in easy-to-analyze CSV format
- **Comprehensive Coverage**: Captures all relevant directory information
- **Sorted Output**: Results are sorted alphabetically for easy browsing

## Use Cases
- **Directory Audits**: Reviewing organizational address lists and their configurations
- **User Inventory**: Getting a complete list of all users and their email addresses
- **Compliance Reporting**: Generating directory reports for compliance requirements
- **Migration Planning**: Understanding current directory structure before migrations

## Output Locations
- Address Lists: `~/all-addresslists.csv`
- GAL Users: `~/gal-emails.csv`

Both files are saved to the user's home directory (~).

## Example Output

### Address Lists Export
```csv
Name,RecipientFilter
"All Contacts","((RecipientType -eq 'MailContact'))"
"All Groups","((RecipientType -eq 'MailUniversalDistributionGroup'))"
"Default Global Address List","((Alias -ne $null) -and (((RecipientType -eq 'UserMailbox')))"
```

### GAL Users Export
```csv
Name,PrimarySmtpAddress
"John Doe","john.doe@company.com"
"Jane Smith","jane.smith@company.com"
"Admin User","admin@company.com"
```

## Notes
- Both scripts require active Exchange Online connection
- Scripts will prompt for authentication if not already connected
- Output files will be overwritten if they already exist
- Large organizations may experience longer export times
