function ExecuteUpdates {

    Write-Host "Updating NuKeeper"
    # install nukeeper in this location
    $version = 0.34
    dotnet tool update nukeeper --version $version --tool-path $PSScriptRoot

    Write-Host "Calling nukeeper"
    # get update info from NuKeeper
    $updates = .$PSScriptRoot\nukeeper inspect --outputformat csv

    Write-Host "Checking for updates"
    # since the update info is in csv, we'll need to search
    $updatesFound = $false
    foreach ($row in $updates) {
        if ($row.IndexOf("possible updates") -gt -1) {
            Write-Host "Found updates row [$row]"; 
            if ($row.IndexOf("Found 0 possible updates") -gt -1) {
                Write-Host "There are no updates"
            }
            else {
                Write-Host "There are updates"
                $updatesFound = $true                
            }
            break
        }
    }   

    if ($updatesFound) {
        UpdatePackages
    }

    return $updatesFound
}

function UpdatePackages {
    # call the nukeeper tool to update all projects
    # -a is PackageAge where 0 == immediately
    # -m is the maximum number of Packages to update (defaults to 1!)
    .$PSScriptRoot\nukeeper update -a 0 -m 10000000
}