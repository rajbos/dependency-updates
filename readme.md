
# Dependency updates
This repository has been created to have a open source version of tools created to update your code dependencies in a reproducible way. Since the mainstream methods only work against the cloud versions of the repositories hosting parties and not against a private server, I needed an easy way to do this for multiple projects.

## Supported ways to update
- NuGet
- Yarn
- NPM

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
My main usage for this image is to use it in a GitLab, as simple as possible. Below are the examples for NuGet and Yarn against a GitLab private server that we run on a schedule:

### NuGet + GitLab
To update NuGet packages we use [NuKeeper](http://nukeeper.com/) to check for updates.
``` yaml
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

### Yarn + GitLab
To update NPM packages with Yarn we use the default `yarn upgrade` command and check with `git diff-index HEAD` if there are any changed files.

Full set of yarn commands we trigger:
``` shell
yarn
yarn eslint
yarn build
yarn upgrade
```
Job example:
``` yaml
yarn_update:on-schedule:
  stage: update-yarn
  only:
    - schedules
  image: 
    name: ghcr.io/rajbos/local-dependency-updates:latest
  script:   
    - export PAT=$GitLabToken # load the GitLab access token from GitLab in the env vars 
    - export branchPrefix="yarn-updates" # prefix to use for the new branch 
    # we need npm authentication for this project
    - echo "" >> .npmrc # add a new line first
    - curl -u${CREDENTIALS} $NPM_REGISTRY_AUTH >> .npmrc # add the credentials to login to e.g. a private Artefactory
    - echo "registry=$NPM_REGISTRY" >> .npmrc # add the private registry url
    # make sure the npmrc file is in the right location so yarn can use it
    - cp .npmrc $CI_BUILDS_DIR/../dependency-updates/
    - cd $CI_BUILDS_DIR/../dependency-updates
    - pwsh start.ps1 yarn gitlab
```

## Additional parameters
The following startup parameters can be used:
|Name|Description|Example|
|---|---|---|
|updateType|Method to use for getting updates|yarn, nuget, npm|
|targetType|Target repository type|gitlab|
|mergeRequestTitle|Title to use for the merge request|Defaults to 'Bumping NuGet/NPM packages'|
|mergeWhenPipelineSucceeds|Bool in indicating if we set the flag 'merge when the pipeline succeeds' in GitLab|0 or 1|
|specificPackages|Yarn only: only update the packages in the parameter|'package A', 'package B'|

# Building the container

```
docker build -t local-dependency-updates:latest .
```

# Run the container
You can run the container locally with the following command to load PowerShell:
```
 docker run -it -e gitUserName="rajbos" -e gitUserEmail="your-email@acme.com" `
   -e remoteUrl="https://github.com/rajbos/dependency-updates" `
   local-dependency-updates:latest `
   pwsh
```

Then you can setup any environment variables you need and run the script:
```
$MERGE_REQUEST_TITLE="Testing dependency updates"
./dependency-updates/start.ps1 -updateType 'yarn' -targetType 'gitlab' -mergeWhenPipelineSucceeds 0 -mergeRequestTitle '$MERGE_REQUEST_TITLE' -specificPackages '@types/react'
```

# Testing with a .NET 5.0 sample solution
After building the container you can run the local container against an example GitHub repository:
``` shell
docker run -it -e gitUserName="rajbos" -e gitUserEmail="your-email@acme.com" `
  -e remoteUrl="https://github.com/rajbos/dependency-updates" `
  local-dependency-updates:latest `
 pwsh start.ps1 -updateType "nuget"
```
