
# 3. Get all Address Lists
Get-AddressList |
  Select-Object Name,RecipientFilter |
  Sort-Object Name |
  Export-Csv ~/all-addresslists.csv -NoTypeInformation

Write-Host "All Address Lists exported to ~/all-addresslists.csv"


