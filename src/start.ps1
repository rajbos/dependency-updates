param (
    [string] $updateType,
    [string] $targetType
)

function ExtractParametersFromGitLabEnvironmentVariables {
    # PAT: cannot use CI PAT since it has no repo rights
    if ($null -ne $env:CI_PROJECT_URL) { $env:remoteUrl = "$($env:CI_PROJECT_URL).git" }
    if ($null -ne $env:CI_PROJECT_ID) { $env:gitLabProjectId = $env:CI_PROJECT_ID }
    if ($null -ne $env:GITLAB_USER_EMAIL) { $env:gitUserEmail = $env:GITLAB_USER_EMAIL }
    if ($null -ne $env:GITLAB_USER_NAME) { $env:gitUserName = $env:GITLAB_USER_NAME }

    Write-Host "Loaded runtime parameters from GitLab environment variables:"
    Write-Host " - remote url: [$($env:remoteUrl)]"
    Write-Host " - gitLabProjectId: [$($env:gitLabProjectId)]"
    Write-Host " - gitUserEmail: [$($env:gitUserEmail)]"
    Write-Host " - gitUserName: [$($env:gitUserName)]"
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
        [string] $targetBranch = "main",
        [string] $mergeRequestTitle = "Bumping NuGet versions"
    )

    Write-Host "Creating new GitLab merge request for project with Id [$gitLabProjectId] from sourcebranch [$branchName] with prefix [$branchPrefix] to target branch [$targetBranch] using title [$mergeRequestTitle]"

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
                                      -title $mergeRequestTitle
}

function Get-UpdatesAvailable {
    $updatesAvailable = $false
    switch ($updateType) {
        "nuget" {
            # run nukeeper updates on repo
            Write-Host "Running nuget updates"
            . $PSScriptRoot\nukeeper.ps1

            $updatesAvailable = ExecuteUpdates
        }
        "yarn" {
            # run yarn updates on repo
            Write-Host "Running yarn updates"
            . $PSScriptRoot\yarn.ps1

            $updatesAvailable = (ExecuteUpdates)[-1]
        }
        Default {
            Write-Error "Please specify an updateType to execute on the repository. Supported: [""nuget"", ""yarn""]"
        }
    }

    return $updatesAvailable
}

function HandleUpdates {
    param (
        [string] $mergeRequestTitle
    )
    switch ($targetType) {
        "gitlab" {  
            Write-Host "Running against GitLab setup"
            if ($null -eq $env:gitLabProjectId) {
                Write-Error "Please specify [$$env:gitLabProjectId] with a projectId to use. This number can be found on the project page"
            }
            CreateMergeRequestGitLab -branchName "$branchName" -branchPrefix $branchPrefix -gitLabProjectId $env:gitLabProjectId -mergeRequestTitle $mergeRequestTitle
        }
        Default {
            Write-Error "Please specify a targetTpe to target. Supported: ""gitlab"""
        }
    }
}

function GetMergeRequestTitle {
    param (
        [string] $updateType
    )

    switch ($updateType) {
        "yarn" { return "Bumping NPM package versions"; }
        "nuget" { return "Bumping NuGet packages versions"; }
        Default {
            Write-Error "Please specify an targetType to execute on the repository. Supported: ""yarn"", ""nuget"", got value [$updateType]"
        }
    }

}

function Main {
    # main execution code
    Write-Host "updateType = [$updateType], targetType=[$targetType]"

    switch ($targetType) {
        "gitlab" {
            ExtractParametersFromGitLabEnvironmentVariables
        }
        Default {
            Write-Error "Please specify an targetType to execute on the repository. Supported: ""gitlab"""
        }
    }


    # import git functions
    Set-Location $PSScriptRoot
    . .\git.ps1 -PAT $env:PAT -RemoteUrl $env:remoteUrl -gitUserEmail $env:gitUserEmail -gitUserName $env:gitUserName -branchPrefix $env:branchPrefix
    # clone the repo
    SetupGit 

    # run the selected check to see if there are any updates
    $updatesAvailable = Get-UpdatesAvailable

    # handle any updates with the selected target type
    if ($updatesAvailable) {
        Write-Host "Found updates, handling them with Git"
        $branchName = HandleUpdatesWithGit
        Write-Host "Updates are in branch [$branchName]"
        if ($null -eq $branchName -or $branchName.Length -eq 0) {
            Write-Warning "Something went wrong with Git handling. Stopping further execution"
            return
        }

        $mergeRequestTitle = GetMergeRequestTitle -updateType $updateType
        Write-Host "Using [$mergeRequestTitle] as the merge request title"
        HandleUpdates -mergeRequestTitle $mergeRequestTitle
    }
}


# call the main execution code
Main