#!/bin/bash
# Count LoC for a Azure DevOps organization

if [ $# -lt 2 ]; then
    echo "Usage: `basename $0` <token> <org>"
    exit
fi

apiBase=https://dev.azure.com/
token=$1
org=$2

rawurlencode() {
  local string="${1}"
  local strlen=${#string}
  local encoded=""
  local pos c o

  for (( pos=0 ; pos<strlen ; pos++ )); do
     c=${string:$pos:1}
     case "$c" in
        [-_.~a-zA-Z0-9] ) o="${c}" ;;
        * )               printf -v o '%%%02x' "'$c"
     esac
     encoded+="${o}"
  done
  echo "${encoded}"    # You can either set a return variable (FASTER) 
  REPLY="${encoded}"   #+or echo the result (EASIER)... or both... :p
}

reposJson=$(curl -f -s -u ":$token" $apiBase$org/_apis/git/repositories?api-version=6.0)

echo $reposJson
readarray -t repos < <(jq -c '.value[] | {name: .name, project: .project.id, default_branch: .defaultBranch}' <<< $reposJson)

for repo in "${repos[@]}"; do
    name=$(jq -r '.name' <<< $repo)
    branch=$(jq -r '.default_branch' <<< $repo)
    echo $name  - $branch    
done

fileList=""

for repo in "${repos[@]}"; do
    name=$(jq -r '.name' <<< $repo)
    remote_branch=$(jq -r '.default_branch' <<< $repo)
    branch=${remote_branch##*/}
    project=$(jq -r '.project' <<< $repo)
    encodedproject=$( rawurlencode "$project" )
    encodedname=$( rawurlencode "$name" )
    remoteUrl="https://$token@dev.azure.com/$org/$encodedproject/_git/$encodedname"
    fileList+="$encodedname.cloc "
    echo Checking out $name - $branch
    git clone $remoteUrl --depth 1 --branch "$branch" "$name"
    echo Counting $name - $branch
    cloc "$name" --force-lang-def=sonar-lang-defs.txt --report-file="$encodedname.cloc"
    rm -rf $name
done

echo "Building final report:"

cloc --sum-reports --force-lang-def=sonar-lang-defs.txt --report-file=$org $fileList
rm *.cloc

exit 0;

