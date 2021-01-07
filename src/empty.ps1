Write-Host "Welcome to the dependency updater"

# search for the location of the start file
Get-Childitem "start.ps1" -Recurse

cd ~

Get-Childitem "start.ps1" -Recurse