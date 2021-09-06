function ExecuteUpdates {
    param (
        [array] $specificPackages
    )
   
    # check for updates with yarn:
    Write-Host "Running command [npm]"
    npm
    Write-Host "Running command [npm ci]"
    npm ci

    if ($null -eq $specificPackages) {
        Write-Host "npm upgrade all dependencies:"
        npm upgrade
    }
    else {
        foreach ($package in $specificPackages) {
            Write-Host "Running npm upgrade for [$specificPackages]"
            npm upgrade $package --latest
        }
    }
    
    # don't add npmrc to the history
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