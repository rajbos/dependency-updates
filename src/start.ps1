param (
    [string] $updateType,
    [string] $targetType,    
    [string] $mergeRequestTitle = "",
    [bool] $mergeWhenPipelineSucceeds = $true,
    [array] $specificPackages,
    [string] $updateFolder
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

    if ($null -ne $updateFolder) {
        Write-Host "Update commands will run from this folder: [$updateFolder]"
    }
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
        [string] $mergeRequestTitle = "Bumping NuGet versions",
        [boolean] $mergeWhenPipelineSucceeds
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
                                      -title $mergeRequestTitle `
                                      -mergeWhenPipelineSucceeds $mergeWhenPipelineSucceeds
}

function Get-UpdatesAvailable {
    param (
        [string] $updateFolder,
        [array] $specificPackages
    )

    $updatesAvailable = $false
    if ($null -ne $updateFolder) {
        Set-Location $updateFolder
    }
    switch ($updateType) {
        "nuget" {
            # run nukeeper updates on repo
            Write-Host "Running nuget updates"
            . $PSScriptRoot\nukeeper.ps1

            $updatesAvailable = (ExecuteUpdates)[-1]
            Write-Host "UpdatesAvailable result from NuGet = [$updatesAvailable]" 
        }
        "yarn" {
            # run yarn updates on repo
            Write-Host "Running yarn updates from $(Get-Location)"
            . $PSScriptRoot\yarn.ps1
            
            if ($null -ne $specificPackages) {
                Write-Host "Checking only these packages: [$specificPackages]"
            }

            $result = ExecuteUpdates -specificPackages $specificPackages
            $updatesAvailable = $result[-1]
        }
        "npm" {
            # run npm updates on repo
            Write-Host "Running npm updates"
            . $PSScriptRoot\npm.ps1
            
            if ($null -ne $specificPackages) {
                Write-Host "Checking only these packages: [$specificPackages]"
            }

            $result = ExecuteUpdates -specificPackages $specificPackages
            $updatesAvailable = $result[-1]
        }
        Default {
            Write-Error "Please specify an updateType to execute on the repository. Supported: [""nuget"", ""yarn"", ""npm""]"
        }
    }

    return $updatesAvailable
}

function HandleUpdates {
    param (
        [string] $mergeRequestTitle,
        [boolean] $mergeWhenPipelineSucceeds,
        [string] $targetBranch
    )
    switch ($targetType) {
        "gitlab" {  
            Write-Host "Running against GitLab setup"
            if ($null -eq $env:gitLabProjectId) {
                Write-Error "Please specify [$$env:gitLabProjectId] with a projectId to use. This number can be found on the project page"
            }
            CreateMergeRequestGitLab -branchName "$branchName" -branchPrefix $branchPrefix -gitLabProjectId $env:gitLabProjectId -mergeRequestTitle $mergeRequestTitle -mergeWhenPipelineSucceeds $mergeWhenPipelineSucceeds -targetBranch $targetBranch
        }
        Default {
            Write-Error "Please specify a targetType to target. Supported: ""gitlab"""
        }
    }
}

function GetMergeRequestTitle {
    param (
        [string] $updateType
    )

    switch ($updateType) {
        "yarn" { return "Bumping NPM package versions"; }
        "npm" { return "Bumping NPM package versions"; }
        "nuget" { return "Bumping NuGet packages versions"; }
        Default {
            Write-Error "Please specify an targetType to execute on the repository. Supported: ""yarn"", ""nuget"", got value [$updateType]"
        }
    }

}

function Check-NPMrc {
    param (
        [string] $updateFolder
    )
    $startLocation=Get-Location
    Set-Location $PSScriptRoot

    # test for .npmrc file in the root, if available, copy it to updateFolder
    if ($true -eq (Test-Path ".npmrc" -PathType Leaf)) {
        Write-Host "Found .npmrc file in script root"
        if ($true -eq (Test-Path ".\src\$updateFolder" -PathType Container)) {
            # copy the npmrc file over
            Copy-Item ".npmrc" ".\src\$updateFolder\.npmrc"
            Write-Host "Copied .npmrc from [$(Get-Location)] to [.\src\$updateFolder]"
        }
    }

    Set-Location $startLocation
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
    $results = SetupGit
    $targetBranch = $results[-1] 

    Check-NPMrc -updateFolder $updateFolder

    # run the selected check to see if there are any updates
    $updatesAvailable = Get-UpdatesAvailable -updateFolder $updateFolder -specificPackages $specificPackages

    # handle any updates with the selected target type
    if ($updatesAvailable) {
        Write-Host "Found updates, handling them with Git"
        $branchName = HandleUpdatesWithGit
        Write-Host "Updates are in branch [$branchName]"
        if ($null -eq $branchName -or $branchName.Length -eq 0) {
            Write-Warning "Something went wrong with Git handling. Stopping further execution"
            return
        }

        if ($mergeRequestTitle.Length -eq 0) {
            # load from updateType
            $mergeRequestTitle = GetMergeRequestTitle -updateType $updateType
        }
        Write-Host "Using [$mergeRequestTitle] as the merge request title for target branch [$targetBranch]"
        HandleUpdates -mergeRequestTitle $mergeRequestTitle -mergeWhenPipelineSucceeds $mergeWhenPipelineSucceeds -targetBranch $targetBranch
    }
}

# call the main execution code
Main