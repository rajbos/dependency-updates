function ExecuteUpdates {
   
    # check for updates with yarn:
    yarn
    yarn eslint
    yarn build
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