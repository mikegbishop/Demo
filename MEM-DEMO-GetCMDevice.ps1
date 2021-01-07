Get-Command -Module ConfigurationManager | Where-Object {$_.Name -like 'Get-*'} 

Get-CMDevice

Get-CMDevice | Select-Object Name
