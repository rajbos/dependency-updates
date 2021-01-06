param (
    [string] $updateType,
    [string] $targetType
)

function HandleUpdatesWithGit {
    $branchName = CreateNewBranch
    CommitAndPushBranch -branchName $branchName

    return $branchName
}

function CreateMergeRequestGitLab {
    param(
        [Parameter(Mandatory=$true)]
        [string] $gitLabProjectId,
        [string] $branchName,
        [string] $targetBranch = "main",
        [string] $branchPrefix
    )

    Write-Host "Creating new GitLab merge request for project with Id [$gitLabProjectId]"

    $gitDir = Get-Location
    # get gitlab functions
    Set-Location $PSScriptRoot
    . .\gitlab.ps1 -baseUrl $remoteUrl -projectId $gitLabProjectId -PAT $PAT

    Set-Location $gitDir
    $sourceBranch = $branchName
    $sourceBranchPrefix = $branchPrefix

    CreateNewMergeRequestIfNoOpenOnes -projectId $gitLabProjectId `
                                      -sourceBranchPrefix $sourceBranchPrefix `
                                      -sourceBranch $sourceBranch `
                                      -targetBranch $targetBranch `
                                      -title "Bumping NuGet versions"
}

# main execution code
Write-Host "updateType = [$updateType], targetType=[$targetType], gitUserName = [$($env:gitUserName)], RemoteUrl=[$($env:remoteUrl)]"

# import git functions
Set-Location $PSScriptRoot
. .\git.ps1 -PAT $env:PAT -RemoteUrl $env:remoteUrl -gitUserEmail $env:gitUserEmail -gitUserName $env:gitUserName -branchPrefix $env:branchPrefix
# clone the repo
SetupGit 

# run the selected check to see if there are any updates
$updatesAvailable = $false
switch ($updateType) {
    "nuget" {
        # run nukeeper updates on repo
        Write-Host "Running nuget updates"
        . $PSScriptRoot\nukeeper.ps1

        $updatesAvailable = ExecuteUpdates
      }
    Default {
        Write-Error "Please specify an updateType to execute on the repository. Supported: ""nuget"""
    }
}

# handle any updates with the selected target type
if ($updatesAvailable) {
    Write-Host "Found updates, handling them with Git"
    $branchName = HandleUpdatesWithGit
    if ($null -eq $branchName -or $branchName.Length -eq 0) {
        Write-Warning "Something went wrong with Git handling. Stopping further execution"
        return
    }

    switch ($targetType) {
        "gitlab" {  
            Write-Host "Running against GitLab setup"
            CreateMergeRequestGitLab -branchName $branchName -branchPrefix $branchPrefix -gitLabProjectId $gitLabProjectId
        }
        Default {
            Write-Error "Please specify a targetTpe to target. Supported: ""gitlab"""
        }
    }
}