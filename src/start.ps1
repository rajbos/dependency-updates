param (
    [string] $updateType

)

Write-Host "updateType = [$updateType], gitUserName = [$($env:gitUserName)], RemoteUrl=[$($env:remoteUrl)]"

switch ($updateType) {
    "nuget" {
        # run nukeeper updates on repo
        Write-Host "Running nuget updates"
        .\nukeeper.ps1 `
            -branchPrefix $env:branchPrefix `
            -gitLabProjectId $env:gitLabProjectId `
            -gitUserName $env:gitUserName `
            -gitUserEmail $env:gitUserEmail `
            -remoteUrl $env:remoteUrl `
            -PAT $env:PAT `
      }
    Default {
        Write-Host "Please specify an updateType to execute on the repository"
    }
}