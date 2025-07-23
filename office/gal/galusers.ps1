Get-GlobalAddressList -Identity "Default Global Address List" |
  Get-Recipient -ResultSize Unlimited |
  Select-Object Name,PrimarySmtpAddress |
  Sort-Object Name |
  Export-Csv ~/gal-emails.csv -NoTypeInformation

Write-Host "Export complete: ~/gal-emails.csv"

# 4. (Optional) Disconnect session
