# global variables we use
params (
  [string] $branchPrefix,
  [string] $gitLabProjectId,
  [string] $gitUserName,
  [string] $gitUserEmail,
  [string] $gitLabRemote
)

function ExecuteUpdates {
    param (
        [string] $gitLabProjectId
    )

    git --version
    git config user.email $gitUserEmail
    git config user.name $gitUserName
    # setting token for auth
    git remote rm gitlab # remove if already exists
    git remote add gitlab https://xx:$($env:GitLabToken)@$($GitLabRemote)
    git remote -v
    git pull
    
    # install nukeeper
    dotnet tool update nukeeper --tool-path .

    # get update info
    $updates = .\nukeeper inspect --outputformat csv

    # since the update info is in csv, we'll need to search
    $updatesFound = $false
    foreach ($row in $updates) {
        if ($row.IndexOf("possible updates") -gt -1) {
            Write-Host "Found updates row [$row]"; 
            if ($row.IndexOf("0 possible updates") -gt -1) {
                Write-Host "There are no upates"
            }
            else {
                Write-Host "There are updates"
                $updatesFound = $true
                break
            }
        }
    }

    if ($updatesFound) {
        $branchName = CreateNewBranch
        UpdatePackages
        CommitAndPushBranch -branchName $branchName
        CreateMergeRequest -branchName $branchName -branchPrefix $branchPrefix -gitLabProjectId $gitLabProjectId
    }
    else {
        Write-Host "Found no updates"
    }
}

function UpdatePackages {
    .\nukeeper update
}

function CreateNewBranch {
 # todo: create new branch with git
 $ISODATE = (Get-Date -UFormat '+%Y%m%d')
 $branchName = "$branchPrefix/$ISODATE"
 git checkout -b $branchName
 return $branchName
}

function CommitAndPushBranch {
    param (
        [string] $branchName
    )

    git add .
    git commit -m "NuGet dependencies updated"
    git push --set-upstream gitlab $branchName
}

function CreateMergeRequest {
    param(
        [string] $gitLabProjectId,
        [string] $branchName,
        [string] $targetBranch = "main",
        [string] $branchPrefix
    )

    # get gitlab functions
    . .\GitLab.ps1

    $sourceBranch = $branchName
    $sourceBranchPrefix = $branchPrefix

    CreateNewMergeRequestIfNoOpenOnes -projectId $gitLabProjectId `
                                      -sourceBranchPrefix $sourceBranchPrefix `
                                      -sourceBranch $sourceBranch `
                                      -targetBranch "main" `
                                      -title "Bumping NuGet versions"
}

ExecuteUpdates -gitLabProjectId $gitLabProjectId