LoC Counting Scripts
==================
This is a collection of shell scripts to count lines of code of all repositories accessible by the user.

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

Example for public [github.com](https://github.com):

```
<github_com.sh> myuser 1234567890abcdefgh myGitHubDotComOrg