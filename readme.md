
# Dependency updates
This repository has been created to have a open source version of tools created to update your code dependencies in a reproduceable way.

## Supported ways to update
- NuGet

## Supported targets to create a Pull Request
- GitLab On-premises: [read more](/docs/GitLab.md)

# Examples
## Example running it from GitHub Container Registry
```
docker run -it `
  -e gitUserName="Rob Bos" `
  -e gitUserEmail="rbos@maildomain.com" `
  -e remoteUrl="https://my.gitlab.host/project/repository.git" `
  -e PAT=$env:GITLAB_PAT `
  -e gitLabProjectId="$env:gitLabProjectId" `
  ghcr.io/rajbos/local-dependency-updates:latest `
  pwsh start.ps1 -updateType "nuget" -targetType "gitlab"
```

## Example running it from a GitLab pipeline:
```
nuget_update:on-schedule:
  only:
    - schedules
  image: 
    name: ghcr.io/rajbos/local-dependency-updates:test
  script:
  # we are in /builds/project/repository 
  - export PAT=$GitLabToken # load the GitLab access token storied in GitLab as environment variable 
  - export branchPrefix="nuget-updates" # prefix to use for the new branch
  # run call to update dependencies with settings what to do
  - pwsh .$CI_BUILDS_DIR/../dependency-updates/start.ps1 nuget gitlab
```

# Testing with a .NET 5.0 sample solution

```
docker run -it -e gitUserName="rajbos" -e gitUserEmail="your-email@acme.com" `
  -e remoteUrl="https://github.com/rajbos/dependency-updates" `
  local-dependency-updates:latest `
 pwsh start.ps1 -updateType "nuget"
```

# Building the container

```
docker build -t local-dependency-updates:latest .
```
