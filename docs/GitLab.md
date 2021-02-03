# PAT information:

Create a PAT for the creation of Merge Requests in GitLab.

The PAT token needs to have the following rights:
* Repo: read & write (for cloning and pushing a new branch)
* API: read & write (for listing existing MR's and creating a new one)

We also try to set 'merge when pipeline succeeds on the new Merge Request'. For this to work the Access Token we use must also have Maintainer Rights on the project. If not, you'll see a 401 error on that call.