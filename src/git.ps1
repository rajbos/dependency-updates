# global variables we use
param (
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

    if ($RemoteUrl.StartsWith("https://")) {
        # remove https for further usage
        $RemoteUrl = $RemoteUrl.Substring(8, $RemoteUrl.Length-8)
    }

    if ($PAT -ne '') {
        # use token for auth
        $url = "https://xx:$($PAT)@$($RemoteUrl)"
    }
    else {
        $url = "https://$RemoteUrl"
    }

    Write-Host "Cloning from url [$url]"
    git clone $url
    ls
}