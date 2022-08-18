#!/bin/bash
# Count LoC for a GitLab group

if [ $# -lt 2 ]; then
    echo "Usage: `basename $0` <token> <groupID>"
    exit
fi

apiBase=https://gitlab.com/api/v4

token=$1
groupID=$2
reposJson=""
groupName=$(curl -X GET "PRIVATE-TOKEN: $1" "https://gitlab.com/api/v4/groups/$2" | jq '.path' --raw-output)

echo $groupName
URL="$apiBase/groups/$groupID/projects?per_page=100"
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
  HEADERS=$(echo "$RESP" | gsed '/^\r$/q')
  URL=$(echo "$HEADERS" | gsed -n -E 's/link:.*<(.*?)>; rel="next".*/\1/p')
  if [ $? -ne 0 ]; then
    echo "######################"
    echo "Error with extracting next page link from headers:$HEADERS"
    echo "MacOS users need to switch to a standard gsed implementation, e.g., gnu-gsed"
    echo "######################"
    exit 3
  fi
  reposJson="$reposJson $(echo "$RESP" | gsed '1,/^\r$/d')"
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
# Retrieve list of repos in the group
projectsJson=$(curl -f -s $apiBase/groups/$groupID/projects?private_token=$token)


#readarray -t repos < <(jq -c '.[] | {name: .name, default_branch: .default_branch}' <<< $projectsJson)

echo "Counting code from repos:"
for repo in "${repos[@]}"; do
    name=$(jq -r '.name' <<< $repo)
    branch=$(jq -r '.default_branch' <<< $repo)
    echo $name  - $branch    
done

# Checkout each repo and count code
fileList=""

for repo in "${repos[@]}"; do
    name=$(jq -r '.name' <<< $repo)
    branch=$(jq -r '.default_branch' <<< $repo)
    remoteUrl=https://oauth2:$token@gitlab.com/$groupName/$name.git
    fileList+="$name.cloc "
    echo Checking out $name - $branch
    git clone $remoteUrl --depth 1 --branch $branch $name
    echo Counting $name - $branch
    cloc $name --force-lang-def=sonar-lang-defs.txt --report-file=$name.cloc  
    rm -rf $name
done

# Combine reports
echo "Building final report:"

cloc --sum-reports --force-lang-def=sonar-lang-defs.txt --report-file=$group $fileList
rm *.cloc

exit 0;