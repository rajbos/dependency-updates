Write-Host "Welcome to the dependency updater"

# search for the location of the start file
Get-Children "start.ps1" -Recurse

cd ~

Get-Children "start.ps1" -Recurse