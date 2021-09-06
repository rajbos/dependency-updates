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
    $items = Get-ChildItem -Hidden
    foreach ($item in $items) { Write-Host "- $($item.name)" } 

    $items2 = Get-ChildItem
    foreach ($item in $items2) { Write-Host "- $($item.name)" } 

    $text = Get-Content .npmrc
    Write-Host "NPMRC contents:"
    Write-Host $text
   
    cd ..
    $text = Get-Content .npmrc
    Write-Host "NPMRC contents one level up:"
    Write-Host $text

    cd src

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