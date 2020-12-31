function CreateNewBranch {
    $ISODATE = (Get-Date -UFormat '+%Y%m%d')
    $branchName = "$branchPrefix/$ISODATE"
    git checkout -b $branchName
    return $branchName
   }

function CommitAndPushBranch {
    param (
        [string] $branchName,
        [string] $commitMessage = "Dependencies updated"
    )

    git add .
    git commit -m $commitMessage
    Write-Host "Pushing branch with name [$branchName] to upstream"
    git push --set-upstream origin $branchName
}