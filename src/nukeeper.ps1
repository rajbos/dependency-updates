# global variables we use
param (
  [string] $branchPrefix,
  [string] $gitLabProjectId,
  [string] $gitUserName,
  [string] $gitUserEmail,
  [string] $remoteUrl
)

# import git functions
Set-Location $PSScriptRoot
. .\git.ps1 -PAT $env:GitLabToken -RemoteUrl $remoteUrl -gitUserEmail $gitUserEmail -gitUserName $gitUserName -branchPrefix $branchPrefix

function ExecuteUpdates {
    param (
        [string] $gitLabProjectId
    )

    SetupGit    

    # install nukeeper in this location
    dotnet tool update nukeeper --tool-path $PSScriptRoot

    Write-Host "Calling nukeeper"
    # get update info from NuKeeper
    $updates = .$PSScriptRoot\nukeeper inspect --outputformat csv

    Write-Host "Checking for updates"
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
    .$PSScriptRoot\nukeeper update
}

function CreateMergeRequest {
    param(
        [string] $gitLabProjectId,
        [string] $branchName,
        [string] $targetBranch = "main",
        [string] $branchPrefix
    )

    Write-Host "Creating new GitLab merge request"

    $gitDir = Get-Location
    # get gitlab functions
    Set-Location $PSScriptRoot
    . .\gitlab.ps1 -baseUrl $remoteUrl -projectId $gitLabProjectId

    Set-Location $gitDir
    $sourceBranch = $branchName
    $sourceBranchPrefix = $branchPrefix

    CreateNewMergeRequestIfNoOpenOnes -projectId $gitLabProjectId `
                                      -sourceBranchPrefix $sourceBranchPrefix `
                                      -sourceBranch $sourceBranch `
                                      -targetBranch "main" `
                                      -title "Bumping NuGet versions"
}

Write-Host "Running nukeeper with branchPrefix [$branchPrefix], gitLabProjectId [$gitLabProjectId], gitUserName [$gitUserName], gitUserEmail [$gitUserEmail], remoteUrl [$remoteUrl]"
ExecuteUpdates -gitLabProjectId $gitLabProjectId