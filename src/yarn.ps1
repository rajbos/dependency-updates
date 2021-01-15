function ExecuteUpdates {
   
    # check for updates with yarn:
    Write-Host "yarn:"
    yarn
    Write-Host "yarn eslint:"
    yarn eslint
    Write-Host "yarn build:"
    yarn build
    Write-Host "yarn upgrade:"
    yarn upgrade

    # use git status to check if there are any changed files
    $status = git diff-index HEAD
    $updatesFound = ($status.Length -gt 0)

    # dont add npmrc to the history
    git restore .npmrc

    if ($updatesFound) {
        Write-Host "Found updates"       
    }
    else {
        Write-Host "Found no updates"
    }

    return $updatesFound
}