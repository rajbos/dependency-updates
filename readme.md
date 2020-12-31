
# Dependency updates
This repository has been created to have a open source version of tools created to update your code dependencies in a reproduceable way.

# Building the container

```
docker build -t local-dependency-updates:latest .
```

# Testing with a .NET 5.0 sample solution

```
docker run -it -e gitUserName="rajbos" -e gitUserEmail="your-email@acme.com" -e remoteUrl="https://github.com/rajbos/dependency-updates" local-dependency-updates:latest nuget
```