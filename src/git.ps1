# global variables we use
param (
  [string] $PAT,
  [string] $branchPrefix,
  [string] $gitUserName,
  [string] $gitUserEmail,
  [string] $RemoteUrl
)

function GetCurrentBranch {
    $branches = (git branch)

    foreach ($branch in $branches) {
        if ($branch.StartsWith("*")) {
            # current branch
            return $branch.Replace("* ", "").Replace("  remotes/origin/", "")
        }
    }
}

function CheckBranchNotExists{
    param (
        [string] $newBranchName
    )

    $branches = git branch --list --all 
    Write-Host "Existing branches found: [$branches]"
    Write-Host "Desired new branch name: [$newBranchName]"
    # search without spaces and the * for the current branch
    $existingBranch = $branches | Where-Object {$_.Replace("* ", "").Replace("  remotes/origin/", "") -eq "$newBranchName"}

    Write-Host "existingBranch = $existingBranch"
    $notExists = ($null -eq $existingBranch -and $existingBranch.Count -ne 1)
    if ($notExists) {
        Write-Host "Desired new branch name does not exist"
    }
    else {
        Write-Host "Desired new branch name already exists"
    }
    return $notExists
}

function GetNewBranchName {
    $ISODATE = (Get-Date -UFormat '+%Y%m%d')
    if ($branchPrefix -eq "") {
        $branchName = "$ISODATE"
    }
    else {
        $branchName = "$branchPrefix/$ISODATE"
    }

    return $branchName
}

function CreateNewBranch {
   
    $branchName = GetNewBranchName

    if ($true -eq (CheckBranchNotExists -newBranchName $branchName)) {
        Write-Host "Creating new branchName [$branchName]"
        git checkout -b $branchName
    }
    
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
    Write-Host "Setting up git with url [$RemoteUrl], email address [$gitUserEmail] and user name [$gitUserName]"

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
    
    $directory="src" 
    if (Test-Path -Path $directory -PathType Container) {
        Write-Host "Clearing [$directory] folder before cloning"
        Remove-Item $directory -Recurse -Force
    }
    
    # create the (new) the folder and move into it
    New-Item -Path $directory -ItemType Directory | Out-Null
    Set-Location $directory

    Write-Host "Cloning from url [$RemoteUrl] into directory [$directory]"
    $status = (git clone $url . 2>&1)
    foreach ($obj in $status) {
        Write-Host $obj
        if ($obj.ToString().Contains("fatal: could not read Username for")) {
            Write-Error "Cannot clone repository. Seems like we need authentication. Please provide setting [$$env:PAT]"
            throw
        }

        if ($obj.ToString().Contains("fatal: Authentication failed for")) {
            Write-Error "Error cloning git repo with authentication failure:"
            Write-Error $obj.ToString()
            throw
        }

        if ($obj.ToString().Contains("fatal")) {
            Write-Error "Error cloning git repo:"
            Write-Error $obj.ToString()
            throw
        }
    }
    
    git config user.email $gitUserEmail
    git config user.name $gitUserName

    $targetBranch = GetCurrentBranch

    $branchName = GetNewBranchName
    if ($false -eq (CheckBranchNotExists -newBranchName $branchName)) {
        Write-Host "Target branch with name [$branchName] already exists, will use it"
        git checkout $branchName
    }

    return $targetBranch
}