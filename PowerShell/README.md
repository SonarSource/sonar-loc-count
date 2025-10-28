![Shell Script](https://img.shields.io/badge/shell_script-%23121011.svg?style=for-the-badge&logo=gnu-bash&logoColor=white)

# LoC Counting PowerShell Scripts

This is a collection of PowerShell scripts that demonstrate how to count lines of code from repositories and/or local directories. These scripts can be used to estimate LoC counts that would be produced by a Sonar analysis of these projects, without having to implement this analysis.
These scripts analyze the repositories and the associated branches.

To count the number of lines of code per language we use the [cloc utility](https://github.com/AlDanial/cloc) of Albert Danial.


## Prerequisites

Before you get started, you’ll need to have these things:
* PowerShell 7.3.0+
* [cloc](https://github.com/AlDanial/cloc/releases/tag/v1.96)  installed v1.96
* Git installed


These scripts generates a report file by repositories : xxx.cloc

## Usage

Local Filesystem :

Counts lines of code from a local directory or file

```
./filesystem.ps1 <directory> <PATH for cloc binary>
```

### [Azure DevOps Services](https://dev.azure.com):

Counts lines of code from a Azure DevOps Services organization. Requires to pass [personal access token](https://docs.microsoft.com/en-us/azure/devops/organizations/accounts/use-personal-access-tokens-to-authenticate?view=azure-devops) and the organization.  The token must have Code Read permissions.
The script generates a report per project (File: ***ProjectName.txt***) that indicates the number of lines of code per branch and indicates the branch that has the highest number of lines of code. As well as a ***global.txt*** file that indicates the maximum line of code on the repository.

```
<azuredevops.ps1> <token> <organization> <PATH for cloc binary>
.\azuredevops.ps1 1234567890abcdefgh myADOOrg $HOME_CLOC/bin/cloc.exe
```
or
```
<azuredevops.ps1> <token> <organization> <MyProjectName>
.\azuredevops.ps1 1234567890abcdefgh myADOOrg $HOME_CLOC/bin/cloc.exe MyProjectName
```
### [github.com](https://github.com):

Counts lines of code from a GitHub.com organization.  Requires to pass username, [personal access token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token) and the organization.  The token must have repo scope.  The script generates a report that lists the count per repository (File : ***OrgName.file***), as well as a report that lists the count by language (File : ***OrgName.lang***).

```
<github_com.ps1> <token> <organization> <PATH for cloc binary>
.\github_com.ps1 1234567890abcdefgh myGitHubDotComOrg $HOME_CLOC/bin/cloc.exe
```
or
```
<github_com.ps1> <token> <organization> <PATH for cloc binary> <MyRepoName>
.\github_com.ps1 1234567890abcdefgh myGitHubDotComOrg $HOME_CLOC/bin/cloc.exe MyRepoName
```

### [Gitlab.com](https://gitlab.com):

Counts lines of code from a GitLab.com Group or Project. Requires passing [personal access token](https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html) and the group. The token must have read_api and read_repository scopes. The script generates a report per project (File: ***ProjectName.txt***) that indicates the number of lines of code per branch and indicates the branch that has the highest number of lines of code. As well as a ***global.txt*** file that indicates the maximum line of code on the repository.

```
<gitlab_com.ps1> <token> <groupName> <PATH for cloc binary>
.\gitlab_com.ps1 1234567890abcdefgh myGitLabGroupName $HOME_CLOC/bin/cloc.exe
```
or
```
<gitlab_com.ps1> <token> <groupName/MyProjectName> <PATH for cloc binary> 
.\gitlab_com.ps1 1234567890abcdefgh myGitLabGroupName/MyProjectName $HOME_CLOC/bin/cloc.exe
```
       
### [bitbucket.org](https://bitbucket.org):

Counts lines of code from a Bitbucket.org workspace or individual repository. Requires passing username (e.g. email), [API token](https://support.atlassian.com/bitbucket-cloud/docs/api-tokens/) with `read:repository:bitbucket` scope, workspace slug, and path to cloc binary. The token must have Repositories Read permissions. 

The script can operate at two levels:
- **Workspace level**: Analyzes all repositories in the workspace
- **Repository level**: Analyzes a single specified repository

The script generates a report per project (File: ***ProjectName.txt***) that indicates the number of lines of code per branch and indicates the branch that has the highest number of lines of code. As well as a ***global.txt*** file that indicates the maximum line of code on the repository.

**Workspace level (all repositories):**
```
<bitbucket_org.ps1> <user> <apiToken> <workspace> <clocPath>
.\bitbucket_org.ps1 myBitbucketemail@workplace.com 1234567890abcdefgh myBBWorkspace C:\path\to\cloc.exe
```

**Repository level (single repository):**
```
<bitbucket_org.ps1> <user> <apiToken> <workspace> <repoName> <clocPath>
.\bitbucket_org.ps1 myBitbucketemail@workplace.com 1234567890abcdefgh myBBWorkspace my-repo C:\path\to\cloc.exe
```
