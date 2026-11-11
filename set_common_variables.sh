
#!/bin/bash -x
#
#
if [[ "$OSTYPE" == "darwin"* ]]; then
  # ...
  echo "darwin / MacOS recognized, let's use gsed"
  SED="gsed"
else
  # let's assume sed is gsed
  echo "Not on MacOS, using the standard sed"
  SED="sed"
fi

source ./require_tools.sh
require_tools "$SED" cloc jq curl git

i=1
LISTF=""
LIST=""
NBCLOC="cpt.txt"
cpt=0
EXCLUDE=".clocignore"
WORKDIR="tmp"         # gitignored scratch dir for clones and per-branch .cloc files
REPORTDIR="reports"   # gitignored dir for per-repo and global reports
pagelen=100
