# global variables we use
params (
  [string] $PAT,
  [string] $branchPrefix,
  [string] $gitUserName,
  [string] $gitUserEmail,
  [string] $RemoteUrl
)

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

function SetupGit {
    git --version
    git config user.email $gitUserEmail
    git config user.name $gitUserName
    # use token for auth
    git clone https://xx:$($PAT)@$($RemoteUrl)
}