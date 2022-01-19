#!/bin/bash
# Count LoC for GitHub repos/organizations

if [ $# -lt 3 ]; then
    echo "Usage: `basename $0` <user>:<token> <github-api-url> <org>"
    exit
fi

apiBase=https://api.github.com
user=$1
token=$2
org=$3

reposJson=$(curl -f -s -u "$user:$token" $apiBase/orgs/$org/repos)

readarray -t repos < <(jq -c '.[] | {name: .name, full_name: .full_name, default_branch: .default_branch}' <<< $reposJson)

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

