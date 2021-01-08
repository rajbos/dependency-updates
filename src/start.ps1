param (
    [string] $updateType,
    [string] $targetType
)

function ExtractParametersFromGitLabEnvironmentVariables {
    # PAT  cannot use CI PAT since it has no repo rights
    $env:remoteUrl = "$($env:CI_PROJECT_URL).git"
    $env:gitLabProjectId = $env:CI_PROJECT_ID
    $env:gitUserEmail = $env:GITLAB_USER_EMAIL
    $env:gitUserName = $env:GITLAB_USER_NAME
    #-branchPrefix $env:branchPrefix

    Write-Host "Loaded runtime parameters from GitLab environment variables:"
    Write-Host " - remote url: [$($env:remoteUrl)]"
    Write-Host " - gitLabProjectId: [$($env:gitLabProjectId)]"
    Write-Host " - gitUserEmail: [$($env:gitUserEmail)]"
    Write-Host " - gitUserName: [$($env:gitUserName)]"

    $env:PAT = $env:CI_JOB_TOKEN
}

function HandleUpdatesWithGit {
    $branchName = CreateNewBranch
    Write-Host "Updates will be added to branch [$branchName]"
    CommitAndPushBranch -branchName $branchName | Out-Null

    Write-Host "Updates added to branch [$branchName]"
    return $branchName
}

function CreateMergeRequestGitLab {
    param(
        [Parameter(Mandatory=$true)]
        [string] $gitLabProjectId,
        [string] $branchName,
        [string] $branchPrefix,        
        [string] $targetBranch = "main"
    )

    Write-Host "Creating new GitLab merge request for project with Id [$gitLabProjectId] from sourcebranch [$branchName] with prefix [$branchPrefix] to target branch [$targetBranch]"

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

switch ($targetType) {
    "gitlab" {
        ExtractParametersFromGitLabEnvironmentVariables
      }
    Default {}
}


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
    Write-Host "Updates are in branch [$branchName]"
    if ($null -eq $branchName -or $branchName.Length -eq 0) {
        Write-Warning "Something went wrong with Git handling. Stopping further execution"
        return
    }

    switch ($targetType) {
        "gitlab" {  
            Write-Host "Running against GitLab setup"
            if ($null -eq $env:gitLabProjectId) {
                Write-Error "Please specify [$$env:gitLabProjectId] with a projectId to use. This number can be found on the project page"
            }
            CreateMergeRequestGitLab -branchName "$branchName" -branchPrefix $branchPrefix -gitLabProjectId $env:gitLabProjectId
        }
        Default {
            Write-Error "Please specify a targetTpe to target. Supported: ""gitlab"""
        }
    }
}