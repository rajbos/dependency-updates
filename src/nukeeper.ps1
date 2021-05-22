function ExecuteUpdates {

    Write-Host "Updating NuKeeper"
    # install nukeeper in this location
    $version = 0.34
    dotnet tool update nukeeper --version $version --tool-path $PSScriptRoot

    Write-Host "Calling nukeeper inspect"
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
        $updatedSuccessfully = UpdatePackages
        if ($updatedSuccessfully -ne $true) {
            Write-Host "Found unsuccesful updates"
            # todo: tell it to the caller so we can skip the auto merge
        }
    }

    return $updatesFound
}

function UpdatePackages {
    # call the nukeeper tool to update all projects
    # -a is PackageAge where 0 == immediately
    # -m is the maximum number of Packages to update (defaults to 1!)
    .$PSScriptRoot\nukeeper update -a 0 -m 10000 

    $result = $?

    if ($result -ne $true) {
        Write-Host "First try gave an error with nukeeper, retrying to be sure..."
        # sometimes nukeeper fails the first time, running it again helps (╯°□°）╯︵ ┻━┻
        $logs = .$PSScriptRoot\nukeeper update -a 0 -m 10000 
        if ($? -ne $true) {
            Write-Host "Second update gave an error as well" 

            foreach ($line in $logs) {
                if ($line.IndexOf('Detected package downgrade') -gt -1) {
                    Write-Error "Found an issue with package downgrading in the current branch"
                    Write-Host "A new branch and merge request will be created, but the build for it should fail."
                    Write-Host "nukeeper logs below:"
                    Write-Host ""
                    Write-Host $logs

                    return $false
                }
            }

          # float the error          
          Write-Host "nukeeper logs:"
          Write-Host $logs          
          Write-Error "Error running nukeeper update, see logs"

          Write-Error "This probably an error with NuKeeper and downgraded packages."
          Write-Error "Please run 'nukeeper update -a 0 -m 10000' from the project/solution root"
          throw
        }
        else {
            Write-Host "Second update was worked!"
        }
    }

    return $true
}