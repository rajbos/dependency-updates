function ExecuteUpdates {

    # update path variable so we can find the nukeeper tool
    $env:PATH="$($env:PATH):/root/.dotnet/tools:/dependency-updates/"
    #Write-Host $env:PATH

    $buildResult = dotnet build
    if (!$?) {
        Write-Host "Build result was not succesful:"
        Write-Host $buildResult
    }

    Write-Host "Calling dotnet outdated"
    $updates = dotnet outdated -o outdated.json
    
    Write-Host "Outdated result: "
    Write-Host $updates
    $json = Get-Content outdated.json | ConvertFrom-Json
    Write-Host ($json | ConvertTo-Json -Depth 10)
    # remove the file so Git will not pick it up later on
    Remove-Item outdated.json
    Write-Host "Outdated output count: [$($json.Count)] and project count: [$($json.Projects.Count)]"

    $foundUpdates = $false
    foreach ($project in $json.Projects) {
        Write-Host "Checking project [$($project.Name)] with $($project.TargetFrameworks.Count) TargetFrameworks"
        foreach ($tfm in $project.TargetFrameworks) {
            Write-Host " For target framework: [$($tfm.Name)]"
            $updates = $tfm.Dependencies | Where-Object {$null -ne $_.LatestVersion }
            if ($updates.Count -gt 0) {
                Write-Host "Found [$($updates.Count)] updates availabe for project [$($project.Name)]:"
                Write-Host ($updates | ConvertTo-Json -Depth 10)
                $foundUpdates = $true
            }
        }        
    }

    if ($foundUpdates) {
        Write-Host "Calling update with dotnet outdated"
        dotnet outdated -u
    }
    
    return $foundUpdates
}