LoC Counting Scripts
==================
This is a collection of shell scripts to count lines of code from repositories and local directories.

* [Installation](#installation)
* [General usage](#general-usage)

Installation
------------

Requirements:

* bash version 4+
* [Git](https://git-scm.com/)
* [curl](https://curl.haxx.se)
* [jq](https://stedolan.github.io/jq/)
* [cloc](https://github.com/AlDanial/cloc)

General usage
-------------

All scripts will produce two reports of LoC by language (.lang) and by repository (.file).

[github.com](https://github.com):

Counts lines of code from a GitHub.com organization.  Requires to pass username, personal access token and the organization.  The token must have repo scope.

```
<github_com.sh> myuser 1234567890abcdefgh myGitHubDotComOrg
```

[bitbucket.org](https://bitbucket.org):

Counts lines of code from a Bitbucket.org organization. Requires to pass username, app password and the workspace slug.  The token must have Repositories > Read permissions.

```
<bitbucket_org.sh> myuser 1234567890abcdefgh myBBWorkspace
```

[Azure DevOps Services](https://dev.azure.com):

Counts lines of code from a Azure DevOps Services organization. Requires to pass personal access token and the organization.  The token must have Code > Read permissions.

```
<azure_devops_services.sh> 1234567890abcdefgh myADOOrg
```
