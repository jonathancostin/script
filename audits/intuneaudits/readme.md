
# Intune Device Compliance Audit Script

## Overview

This PowerShell script audits a Microsoft Intune environment to report on user device compliance. It focuses on devices where a user is either the **Primary User** or the **Device Enroller**. The script generates a CSV report listing users from a specified group, indicating if they are part of a compliant device group, and listing their associated devices horizontally.

## Features

* Connects to Microsoft Graph using the PowerShell SDK.
* Retrieves members from two specified Azure AD groups:
  * An "All Users" group (or a target scope of users).
  * A group used for Conditional Access policies requiring compliant devices.
* Fetches all managed devices from the Intune tenant.
* **Filters devices locally** within the script to accurately associate devices with users based on Primary User (`userId`) or Enroller (`enrolledByUserId`).
* Generates a CSV file with one row per user.
* Device details (Name, OS, Compliance Status, Relationship, etc.) are expanded horizontally across columns (`Device1_Name`, `Device2_Name`, etc.).
* Allows configuration of the maximum number of devices to report per user.

## Parameters

### Required Parameters
| Parameter | Description |
|-----------|-------------|
| **AllUsersGroupId** | The Azure AD group ID containing all users you want to include in the audit |
| **CompliantUsersGroupId** | The dynamic group ID used for Intune compliance enforcement |

### Optional Parameters
| Parameter | Description | Default |
|-----------|-------------|---------|
| **MaxDevices** | Maximum number of devices to report per user | `10` |
| **OutputFile** | Path to export the audit results to | Automatically generated in current directory |

## Usage

Run the script from a PowerShell console, providing the necessary Group IDs:

```powershell
# Run with defaults
Connect-MgGraph -Scopes "User.Read.All", "GroupMember.Read.All", "DeviceManagementManagedDevices.Read.All"
.\IntuneComplianceAudit.ps1 -AllUsersGroupId <GUID_of_All_Users_Group> -CompliantUsersGroupId <GUID_of_Compliant_Devices_Group>

# Run with custom device limit and output file
.\IntuneComplianceAudit.ps1 -AllUsersGroupId <GUID_of_All_Users_Group> -CompliantUsersGroupId <GUID_of_Compliant_Devices_Group> -MaxDevices 15 -OutputFile "C:\Reports\CustomIntuneAudit.csv"
```

## Prerequisites

1.  **PowerShell:** PowerShell 5.1 or later (PowerShell 7+ recommended).
2.  **Microsoft Graph PowerShell SDK Modules:**
    *   `Microsoft.Graph.Users`
    *   `Microsoft.Graph.Groups`
    *   `Microsoft.Graph.DeviceManagement`
    (The script will attempt to install these modules if they are not found, but manual installation via `Install-Module <ModuleName> -Scope CurrentUser` might be necessary).
3.  **Permissions:** The user or service principal running the script needs the following Microsoft Graph API permissions consented in Azure AD:
    *   `User.Read.All`
    *   `GroupMember.Read.All`
    *   `DeviceManagementManagedDevices.Read.All`

## Installation

1.  Download the `IntuneComplianceAudit.ps1` script file to your local machine.
2.  Ensure the prerequisites (PowerShell, Modules, Permissions) are met. The script attempts to install missing modules automatically on first run (requires internet connection and appropriate execution policy).

## Usage

Run the script from a PowerShell console, providing the necessary Group IDs:

```powershell
.\IntuneComplianceAudit.ps1 -AllUsersGroupId <GUID_of_All_Users_Group> -CompliantUsersGroupId <GUID_of_Compliant_Devices_Group> [-MaxDevices <Number>] [-OutputFile <Path_To_CSV>]
