![Shell Script](https://img.shields.io/badge/shell_script-%23121011.svg?style=for-the-badge&logo=gnu-bash&logoColor=white)

# LoC Counting PowerShell Scripts

This is a collection of PowerShell scripts that demonstrate how to count lines of code from repositories and/or local directories. These scripts can be used to estimate LoC counts that would be produced by a Sonar analysis of these projects, without having to implement this analysis.
These scripts analyze the repositories and the associated branches.

To count the number of lines of code per language we use the [cloc utility](https://github.com/AlDanial/cloc) of Albert Danial.


## Prerequisites

Before you get started, you’ll need to have these things:
* PowerShell 7.3.0+
* [cloc](https://sourceforge.net/projects/cloc/files/cloc/v1.64/)  installed
* Git installed


These scripts generates a report file by repositories : xxx.cloc

## Usage

Local Filesystem :

Counts lines of code from a local directory or file

```
./filesystem.ps1 <directory> <PATH for cloc binary>
```

Azure DevOps Services :

Counts lines of code from a Azure DevOps Services organization. Requires to pass [personal access token](https://docs.microsoft.com/en-us/azure/devops/organizations/accounts/use-personal-access-tokens-to-authenticate?view=azure-devops) and the organization.  The token must have Code > Read permissions.

```
./azuredevops.ps1 <azure token>  <organization>  <PATH for cloc binary>
```

GitHub :

Counts lines of code from a GitHub.com organization.  Requires to pass username, [personal access token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token) and the organization.  The token must have repo scope.

```
Coming soon ....
```

GitLab :

Counts lines of code from a GitLab.com Group. Requires to pass [personal access token](https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html) and the group.  The token must have read_api and read_repository scopes.

```
Coming soon ....
```

bitbucket :

Counts lines of code from a Bitbucket.org organization. Requires to pass username, [app password](https://support.atlassian.com/bitbucket-cloud/docs/app-passwords/) and the workspace slug.  The token must have Repositories > Read permissions.

```
Coming soon ....
```