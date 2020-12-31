# collection of GitLab api calls
param (
    [string] $baseUrl,
    [integer] $projectId
)

function GetToken{
    $token = $env:GitLabToken
    
    if ($null -ne $token) {
        Write-Host "Found token as environment variable [GitLabToken]"
    }

    if ($null -eq $token) {
        # try to load gitlab token from pipeline runner
        $token = $CI_JOB_TOKEN

        if ($null -ne $token) {
            Write-Host "Found token from [CI_JOB_TOKEN]"
        }
        else {
            Write-Error "Cannot find GitLab token to use!"
            throw
        }
    }

    return $token
}

$accesToken = GetToken

if ($null -eq $accesToken) {
    Write-Error "Cannot find access token to use for GitLab. Specify env:GitLabToken"
    return
}

function GetFromGitLab{
    param(
        [string] $url
    )

    $urlToCall = "$baseUrl/$url"
    try {
        
        $response = Invoke-RestMethod -Uri $urlToCall -Headers @{"PRIVATE-TOKEN" = $accesToken} -ContentType "application/json" -Method Get
        return $response
    }
    catch {
        Write-Host "Error $_"
    }
}

function PostToGitLab{
    param(
        [string] $url,
        [object] $body
    )

    $urlToCall = "$baseUrl/$url"
    try {
        
        $response = Invoke-RestMethod -Uri $urlToCall -Headers @{"PRIVATE-TOKEN" = $accesToken} -Body $body -ContentType "application/json" -Method Post
        return $response
    }
    catch {
        Write-Host "Error $_"
    }
}

# returns the first matching project with the given searchName 
function GetProjectByName{
    param(
        [string] $searchName
    )

    $url = "projects?simple=true&search=$searchName"
    $response = GetFromGitLab -url $url
    return $response[0]
}

function GetMergeRequests {
    param (
        [string] $projectId,
        [string] $state = "opened"
    )

    $url = "projects/$projectId/merge_requests?state=$state"
    $response = GetFromGitLab -url $url
    return $response
}

function CreateNewMergeRequest{
    param (
        [string] $projectId,
        [string] $sourceBranch,
        [string] $targetBranch,
        [string] $title
    )

    $url = "projects/$projectId/merge_requests"
    $bodyObject = @{
        source_branch = $sourceBranch
        target_branch = $targetBranch
        title = $title
    }

    $body =  (ConvertTo-Json $bodyObject)

    $response = PostToGitLab -url $url -Body $body
    return $response
}


function CreateNewMergeRequestIfNoOpenOnes {
    param (
        [string] $projectId,
        [string] $sourceBranchPrefix,
        [string] $sourceBranch,
        [string] $targetBranch,
        [string] $title
    )
    $mergeRequests = GetMergeRequests -projectId $projectId

    $existingBranchOpen = $false
    foreach ($mr in $mergeRequests | Where-Object {$_.target_branch -eq $targetBranch}) {
        if ($mr.source_branch.StartsWith($sourceBranchPrefix)) {
            Write-Host "Found an existing MR: [$($mr.web_url)]"
            $existingBranchOpen = $true
            break
        }
        else {
            Write-Host "Found an MR that doesn't match the search prefix [$sourceBranchPrefix]: [$($mr.source_branch)]"
        }
    }

    if ($existingBranchOpen) {
        Write-Host "Halting execution. Merge the open source branch first"
        return
    }

    $mr = CreateNewMergeRequest -projectId $projectId -sourceBranch $sourceBranch -targetBranch $targetBranch -title $title
    if ($mr) {
        Write-Host "Created new Merge Request with url [$($mr.web_url)]"
    }
}

function ExampleCalls {
    #$sourceBranch = "nuget-updates\ISODATE"
    #$sourceBranchPrefix = "nuget-updates"
    $sourceBranch = "ISODATE-nuget-updates"
    $sourceBranchPrefix = "ISODATE"

    CreateNewMergeRequestIfNoOpenOnes -projectId $projectId -sourceBranchPrefix $sourceBranchPrefix -sourceBranch $sourceBranch `
                                    -targetBranch "main" -title "Bumping NuGet versions"
}