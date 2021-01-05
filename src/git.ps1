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
    if ($branchPrefix -eq "") {
        $branchName = "$ISODATE"
    }
    else {
        $branchName = "$branchPrefix/$ISODATE"
    }
    Write-Host "New branchname [$branchName]"
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
    Write-Host "Seting up git with url [$RemoteUrl], email address [$gitUserEmail] and user name [$gitUserName]"

    if ($RemoteUrl.StartsWith("https://")) {
        # remove https for further usage
        $RemoteUrl = $RemoteUrl.Substring(8, $RemoteUrl.Length-8)
    }

    if ($PAT -ne '') {
        # use token for auth
        Write-Host "Found a personal access token to use for authentication"
        $url = "https://xx:$($PAT)@$($RemoteUrl)"
    }
    else {
        $url = "https://$RemoteUrl"
    }

    Write-Host "Cloning from url [$RemoteUrl]"
    git clone $url
    
    # load repo name from url
    $repoName=$url.Split('/')[-1].Split('.')[0]
    Write-Host "Moving to repository [$repoName]"
    Set-Location $repoName
    
    git config user.email $gitUserEmail
    git config user.name $gitUserName

    # todo: log branch we are in and add a setting for it
}