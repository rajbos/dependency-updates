# global variables we use
params (
  [string] $branchPrefix,
  [string] $gitLabProjectId,
  [string] $gitUserName,
  [string] $gitUserEmail,
  [string] $gitLabRemote
)

# import git functions
Set-Location $PSScriptRoot
. .\git.ps1

function ExecuteUpdates {
    param (
        [string] $gitLabProjectId
    )

    SetupGit -PAT $env:GitLabToken -RemoteUrl $GitLabRemote -gitUserEmail $gitUserEmail -gitUserName $gitUserName -branchPrefix $branchPrefix
    
    # install nukeeper in this location
    dotnet tool update nukeeper --tool-path .

    # get update info from NuKeeper
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

function CreateMergeRequest {
    param(
        [string] $gitLabProjectId,
        [string] $branchName,
        [string] $targetBranch = "main",
        [string] $branchPrefix
    )

    # get gitlab functions
    . .\GitLab.ps1 -baseUrl $gitLabRemote -projectId $gitLabProjectId

    $sourceBranch = $branchName
    $sourceBranchPrefix = $branchPrefix

    CreateNewMergeRequestIfNoOpenOnes -projectId $gitLabProjectId `
                                      -sourceBranchPrefix $sourceBranchPrefix `
                                      -sourceBranch $sourceBranch `
                                      -targetBranch "main" `
                                      -title "Bumping NuGet versions"
}

ExecuteUpdates -gitLabProjectId $gitLabProjectId