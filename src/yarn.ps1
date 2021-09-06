function ExecuteUpdates {
    param (
        [array] $specificPackages
    )

    # adding debug info for finding config errors:
    Write-Host "NPM Config settings:"
    $list = npm config list
    foreach ($item in $list) { Write-Host "- $item" }

    # checking all files
    Write-Host "Local files: "
    foreach ($item in get-childitem) { Write-Host "- $($item.name)" }   
   
    # check for updates with yarn:
    Write-Host "Running command [yarn]"
    yarn
    Write-Host "Running command [yarn eslint]"
    yarn eslint
    Write-Host "Running command [yarn build]"
    yarn build

    if ($null -eq $specificPackages) {
        Write-Host "yarn upgrade all dependencies:"
        yarn upgrade
    }
    else {
        foreach ($package in $specificPackages) {
            Write-Host "Running yarn upgrade for [$specificPackages]"
            yarn upgrade $package --latest
        }
    }
    
    # dont add npmrc to the history
    git restore .npmrc
    
    # trigger git update after removing the file, to prevent issues
    git status

    # use git status to check if there are any changed files
    $status = git diff-index HEAD
    Write-Host "Git status: " $status
    $updatesFound = ($status.Length -gt 0)

    if ($updatesFound) {
        Write-Host "Found updates"
    }
    else {
        Write-Host "Found no updates"
    }

    return $updatesFound
}