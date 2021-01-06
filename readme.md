
# Dependency updates
This repository has been created to have a open source version of tools created to update your code dependencies in a reproduceable way.

## Supported ways to update
- NuGet

## Supported targets to create a Pull Request
- GitLab On-premises

## Example running it from GitHub Container Registry
```
docker run -it `
  -e gitUserName="Rob Bos" `
  -e gitUserEmail="rbos@maildomain.com" `
  -e remoteUrl="https://my.gitlab.host/project/repository.git" `
  -e PAT=$env:GITLAB_PAT `
  -e gitLabProjectId="$env:gitLabProjectId" `
  ghcr.io/rajbos/local-dependency-updates:latest `
  -updateType "nuget" -targetType "gitlab"
```

# Building the container

```
docker build -t local-dependency-updates:latest .
```

# Testing with a .NET 5.0 sample solution

```
docker run -it -e gitUserName="rajbos" -e gitUserEmail="your-email@acme.com" `
  -e remoteUrl="https://github.com/rajbos/dependency-updates" `
  local-dependency-updates:latest `
  nuget
```