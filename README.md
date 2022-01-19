LoC Counting Scripts
==================
This is a collection of shell scripts to count lines of code from repositories and local directories.

* [Installation](#installation)
* [General usage](#general-usage)

Installation
------------

Requirements:

* bash version 4+
* [Perl](https://www.perl.org/)
* [Git](https://git-scm.com/)
* [curl](https://curl.haxx.se)
* [jq](https://stedolan.github.io/jq/)
* [cloc](https://github.com/AlDanial/cloc)

General usage
-------------

All scripts require to pass username, personal access token and the API endpoint URL.

[github.com](https://github.com):

Counts lines of code from a GitHub.com organization.  Requires to pass username, personal access token and the organization.  The token must have repo scope.

```
<github_com.sh> myuser 1234567890abcdefgh myGitHubDotComOrg

[bitbucket.org](https://bitbucket.org):

Counts lines of code from a GitHBitbucket.org organization. Requires to pass username, personal access token and the workspace.  The token must have repo scope.

```
<bitbucket_org.sh> myuser 1234567890abcdefgh myBBWorkspace
