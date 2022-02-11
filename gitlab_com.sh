#!/bin/bash
# Count LoC for a GitLab group

if [ $# -lt 2 ]; then
    echo "Usage: `basename $0` <token> <group>"
    exit
fi

apiBase=https://gitlab.com/api/v4
token=$1
group=$2

# Retrieve list of repos in the group
projectsJson=$(curl -f -s $apiBase/groups/$group/projects?private_token=$token)

readarray -t repos < <(jq -c '.[] | {name: .name, default_branch: .default_branch}' <<< $projectsJson)

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
    remoteUrl=https://oauth2:$token@gitlab.com/$group/$name.git
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

