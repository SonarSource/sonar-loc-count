#!/bin/bash
# Count LoC for GitHub repos/organizations

if [ $# -lt 3 ]; then
    echo "Usage: `basename $0` <user> <token> <org>"
    exit
fi

apiBase=https://api.github.com
user=$1
token=$2
org=$3

reposJson=""
URL="$apiBase/orgs/$org/repos?per_page=100"
while [ "$URL" ]; do
  echo "Info: checking URL:$URL"
  RESP=$(curl -i -s -f -u "$user:$token" "$URL")
  if [ $? -ne 0 ]; then
    echo "######################"
    echo "Error getting recursive repo information from GitHub with URL:$URL"
    echo "running the command with verbose output enabled:"
    echo "######################"
    curl -i -v -u "$user:$token" "$URL"
    exit 2
  fi
  HEADERS=$(echo "$RESP" | sed '/^\r$/q')
  URL=$(echo "$HEADERS" | sed -n -E 's/link:.*<(.*?)>; rel="next".*/\1/p')
  if [ $? -ne 0 ]; then
    echo "######################"
    echo "Error with extracting next page link from headers:$HEADERS"
    echo "MacOS users need to switch to a standard sed implementation, e.g., gnu-sed"
    echo "######################"
    exit 3
  fi
  reposJson="$reposJson $(echo "$RESP" | sed '1,/^\r$/d')"
done

readarray -t repos < <(jq -c '.[] | {name: .name, full_name: .full_name, default_branch: .default_branch}' <<< $reposJson)
if [ $? -ne 0 ]; then
    echo "######################"
    echo "readarray was added to bash in version 4"
    echo "Make sure this script runs with such bash"
    echo "MacOS users might need to update their bash, and the first line in this script to point at the updated bash"
    echo "######################"
    exit 4
fi

echo "Counting code from repos:"
for repo in "${repos[@]}"; do
    name=$(jq -r '.full_name' <<< $repo)
    branch=$(jq -r '.default_branch' <<< $repo)
    echo $name  - $branch    
done

fileList=""

for repo in "${repos[@]}"; do
    full_name=$(jq -r '.full_name' <<< $repo)
    name=$(jq -r '.name' <<< $repo)
    branch=$(jq -r '.default_branch' <<< $repo)
    remoteUrl=https://$user:$token@github.com/$full_name.git
    fileList+="$name.cloc "
    echo Checking out $full_name - $branch
    git clone $remoteUrl --depth 1 --branch $branch $name
    echo Counting $full_name - $branch
    cloc $name --force-lang-def=sonar-lang-defs.txt --report-file=$name.cloc  
    rm -rf $name
done

echo "Building final report:"

cloc --sum-reports --force-lang-def=sonar-lang-defs.txt --report-file=$org $fileList
rm *.cloc

exit 0;