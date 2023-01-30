![Shell Script](https://img.shields.io/badge/shell_script-%23121011.svg?style=for-the-badge&logo=gnu-bash&logoColor=white)

# LoC Counting PowerShell Scripts

This is a collection of PowerShell scripts that demonstrate how to count lines of code from repositories and/or local directories. These scripts can be used to estimate LoC counts that would be produced by a Sonar analysis of these projects, without having to implement this analysis.
These scripts analyze the repositories and the associated branches.

To count the number of lines of code per language we use the [cloc utility](https://github.com/AlDanial/cloc) of Albert Danial.


## Prerequisites

Before you get started, you’ll need to have these things:
* PowerShell 7.3.0+
* [cloc](https://github.com/AlDanial/cloc)  installed
* Git installed


These scripts generates a report file by repositories : xxx.cloc

## Usage

Local Filesystem :

Counts lines of code from a local directory or file

```
./filesystem.ps1 <directory> <PATH for cloc binary>
```

### [Azure DevOps Services](https://dev.azure.com):

CCounts lines of code from a Azure DevOps Services organization. Requires to pass [personal access token](https://docs.microsoft.com/en-us/azure/devops/organizations/accounts/use-personal-access-tokens-to-authenticate?view=azure-devops) and the organization.  The token must have Code Read permissions.
The script generates a report per project(File : ***ProjectName.txt***) that indicates the number of lines of code per branch and indicates the branch that has the highest number of lines of code.As well as a ***global.txt*** file that indicates the maximum line of code on the repository.

```
<azure_devops_services.sh> <token> <organization> <PATH for cloc binary>
azure_devops_services.sh 1234567890abcdefgh myADOOrg $HOME_CLOC/bin/cloc.exe
```
or
```
<azure_devops_services.sh> <token> <organization> <MyProjectName>
azure_devops_services.sh 1234567890abcdefgh myADOOrg $HOME_CLOC/bin/cloc.exe MyProjectName
```
### [github.com](https://github.com):

Counts lines of code from a GitHub.com organization.  Requires to pass username, [personal access token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token) and the organization.  The token must have repo scope.The script generates a report per project(File : ***ProjectName.txt***) that indicates the number of lines of code per branch and indicates the branch that has the highest number of lines of code.As well as a ***global.txt*** file that indicates the maximum line of code on the repository.

```
<github_com.sh> <user> <token> <organization> <PATH for cloc binary>
github_com.sh myuser 1234567890abcdefgh myGitHubDotComOrg $HOME_CLOC/bin/cloc.exe
```
or
```
<github_com.sh> <user> <token> <organization> <PATH for cloc binary> <MyRepoName>
github_com.sh myuser 1234567890abcdefgh myGitHubDotComOrg $HOME_CLOC/bin/cloc.exe MyRepoName
```

### [Gitlab.com](https://gitlab.com):

Counts lines of code from a GitLab.com Group or Project. Requires to pass [personal access token](https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html) and the group.  The token must have read_api and read_repository scopes.The script generates a report per project(File : ***ProjectName.txt***) that indicates the number of lines of code per branch and indicates the branch that has the highest number of lines of code.As well as a ***global.txt*** file that indicates the maximum line of code on the repository.

```
<gitlab_com.sh> <token> <groupName> <PATH for cloc binary>
gitlab_com.sh 1234567890abcdefgh myGitLabGroupName $HOME_CLOC/bin/cloc.exe
```
or
```
<gitlab_com.sh> <token> <groupName//MyProjectName> <PATH for cloc binary> 
gitlab_com.sh 1234567890abcdefgh myGitLabGroupName/MyProjectName $HOME_CLOC/bin/cloc.exe
```
       
### [bitbucket.org](https://bitbucket.org):

Counts lines of code from a Bitbucket.org organization. Requires to pass username, [App token password](https://support.atlassian.com/bitbucket-cloud/docs/app-passwords/) and the workspace slug.  The token must have Repositories Read permissions.The script generates a report per project(File : ***ProjectName.txt***) that indicates the number of lines of code per branch and indicates the branch that has the highest number of lines of code.As well as a ***global.txt*** file that indicates the maximum line of code on the repository.

```
<bitbucket_org.sh> <user> <PassordToken> <myWorkspace> <PATH for cloc binary>
bitbucket_org.sh myuser 1234567890abcdefgh myBBWorkspace $HOME_CLOC/bin/cloc.exe
```
or
```
<bitbucket_org.sh> <user> <PassordToken> <myWorkspace>  <PATH for cloc binary>  <MyProjectName>
<bitbucket_org.sh> myuser 1234567890abcdefgh myBBWorkspace $HOME_CLOC/bin/cloc.exe MyProjectName
```

