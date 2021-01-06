function ExecuteUpdates {

    Write-Host "Updating NuKeeper"
    # install nukeeper in this location
    dotnet tool update nukeeper --tool-path $PSScriptRoot

    Write-Host "Calling nukeeper"
    # get update info from NuKeeper
    $updates = .$PSScriptRoot\nukeeper inspect --outputformat csv

    Write-Host "Checking for updates"
    # since the update info is in csv, we'll need to search
    $updatesFound = $false
    foreach ($row in $updates) {
        if ($row.IndexOf("possible updates") -gt -1) {
            Write-Host "Found updates row [$row]"; 
            if ($row.IndexOf("There are 0 possible updates") -gt -1) {
                Write-Host "There are no updates"
            }
            else {
                Write-Host "There are updates"
                $updatesFound = $true
                break
            }
        }
    }   

    if ($updatesFound) {
        UpdatePackages
    }

    return $updatesFound
}

function UpdatePackages {
    .$PSScriptRoot\nukeeper update
}