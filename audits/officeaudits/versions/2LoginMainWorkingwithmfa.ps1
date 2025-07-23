# TODO
# add mfa checking
# sort users by most likely to need changes

# Connections
Connect-MgGraph -Scopes "User.Read.All, Directory.Read.All, User.ReadBasic.All, UserAuthenticationMethod.Read.All, AuditLog.Read.All" -NoWelcome
Connect-ExchangeOnline

# Get Dates for use in main loop
$CurrentDate = Get-Date
$OneMonthAgo = $CurrentDate.AddMonths(-1)

# Get all subscribed SKUs once
$SubscribedSkus = Get-MgSubscribedSku

# Build a hashtable of SkuId to SkuPartNumber
$SkuMap = @{}
foreach ($Sku in $SubscribedSkus) {
    $SkuMap[$Sku.SkuId] = $Sku.SkuPartNumber
}

# Function to get the last sign-in date
function Get-LastSignInDate {
    param (
        [Microsoft.Graph.PowerShell.Models.IMicrosoftGraphUser]$User
    )
    # Use the existing signInActivity from the user object
    $LastSignInDate = $User.signInActivity.lastSignInDateTime

    if ($null -eq $LastSignInDate) {
        $LastSignInDate = "Never"
    } else {
        $LastSignInDate = [datetime]$LastSignInDate
    }

    return $LastSignInDate
}

# Function to get the last sent message date
function Get-LastSentMessageDate {
    param (
        [string]$MailId
    )
    
    # Initialize $LastSentTime
    $LastSentTime = $null

    # Check if the user has a mailbox
    $HasMailbox = Get-Recipient -Identity $MailId -ErrorAction SilentlyContinue

    if ($null -ne $HasMailbox) {
        try {
            # Use Get-MailboxFolderStatistics to get the Sent Items folder statistics
            $MailboxStats = Get-MailboxFolderStatistics -Identity $MailId -FolderScope SentItems -IncludeOldestAndNewestItems -ResultSize 5 -ErrorAction Stop

            # Get the 'Sent Items' folder
            $SentItemsFolder = $MailboxStats | Where-Object { $_.FolderType -eq 'SentItems' }

            if ($null -ne $SentItemsFolder) {
                $LastSentTime = $SentItemsFolder.NewestItemReceivedDate

                if ($null -eq $LastSentTime) {
                    $LastSentTime = "No Sent Emails"
                }
            } else {
                $LastSentTime = "No Sent Items Folder"
            }
        } catch {
            Write-Host "Error accessing mailbox for '$MailId': $($_.Exception.Message)"
            $LastSentTime = "Error"
        }
    } else {
        Write-Host "User $MailId does not have a mailbox."
        $LastSentTime = "No Mailbox"
    }

    return $LastSentTime
}

# Function to get assigned licenses
function Get-AssignedLicenses {
    param (
        [Microsoft.Graph.PowerShell.Models.IMicrosoftGraphUser]$User,
        [Hashtable]$SkuMap
    )

    # Define AssignedLicenses
    $AssignedLicenses = $User.AssignedLicenses

    if ($AssignedLicenses -and $AssignedLicenses.Count -gt 0) {
        # Extract the SKU IDs from the assigned licenses
        $skuIds = $AssignedLicenses | Select-Object -ExpandProperty SkuId

        # Map SKU IDs to SKU Part Numbers using the hashtable
        $skuPartNumbers = $skuIds | ForEach-Object {
            $skuId = $_
            $skuPartNumber = $SkuMap[$skuId]
            if ($null -eq $skuPartNumber) {
                $skuPartNumber = $skuId  # Use the SKU ID if Part Number not found
            }
            $skuPartNumber
        }
        return ($skuPartNumbers -join "; ")
    } else {
        return "No Licenses Assigned"
    }
}

# Function to get MFA status for a user
function Get-MfaStatus {
    param (
        [Microsoft.Graph.PowerShell.Models.IMicrosoftGraphUser]$User
    )

    try {
        # Retrieve the Microsoft Authenticator methods for the user
        $authenticatorMethods = Get-MgUserAuthenticationMicrosoftAuthenticatorMethod -UserId $User.Id

        # Retrieve the Software OATH methods for the user
        $oauthMethods = Get-MgUserAuthenticationSoftwareOathMethod -UserId $User.Id

        # Check if the user has the Microsoft Authenticator app or Software OATH tokens registered
        $hasMfa = if ($authenticatorMethods -or $oauthMethods) { "Yes" } else { "No" }

        # Determine MFA Type
        if ($authenticatorMethods -and $oauthMethods) {
            $mfaType = "App/Token"
        } elseif ($oauthMethods) {
            $mfaType = "Token"
        } elseif ($authenticatorMethods) {
            $mfaType = "App"
        } else {
            $mfaType = "SMS/None"
        }

    } catch {
        Write-Host "Failed to retrieve MFA methods for user: $($User.UserPrincipalName)"
        $hasMfa = "Error"
        $mfaType = "Unknown"
    }

    return @{
        HasMfa  = $hasMfa
        MFAType = $mfaType
    }
}

# Initialize an array to hold the results
$Results = @()

# Get all users
$Users = Get-MgUser -All -Select "id,displayName,userPrincipalName,signInActivity,assignedLicenses" | Select-Object -First 10

# Main foreach loop to get user data
foreach ($User in $Users) {
    Write-Host "Processing user: $($User.DisplayName) ($($User.UserPrincipalName))"
    
    # Get the assigned licenses for the user
    $Licenses = Get-AssignedLicenses -User $User -SkuMap $SkuMap

    # Get Last Sign-In Date
    $LastSignInDate = Get-LastSignInDate -User $User

    # Process only users who haven't signed in for over a month
    if ($LastSignInDate -eq "Never" -or $LastSignInDate -lt $OneMonthAgo) {
        # Get UserPrincipalName
        $MailId = $User.UserPrincipalName

        # Get Last Sent Message Date
        $LastSentTime = Get-LastSentMessageDate -MailId $MailId

        # Get MFA Status
        $MfaStatus = Get-MfaStatus -User $User
        $HasMfa = $MfaStatus.HasMfa
        $MFAType = $MfaStatus.MFAType

        # Create a custom object with user info
        $UserInfo = [PSCustomObject]@{
            DisplayName       = $User.DisplayName
            UserPrincipalName = $MailId
            LastSignInDate    = $LastSignInDate
            LastSentMessage   = $LastSentTime
            Licenses          = $Licenses
            HasMfa            = $HasMfa
            MFAType           = $MFAType
        }

        # Add to results
        $Results += $UserInfo
    }
}

# Export the results to a CSV file
$Results | Export-Csv -Path "InactiveUsers.csv" -NoTypeInformation

Write-Host "Report generated: InactiveUsers.csv"
