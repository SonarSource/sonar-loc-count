#!/bin/bash
#set -x
#**************************************************************************#
#                                                                          #
#  @project     : LoC Counting bash Scripts                                #
#  @package     :                                                          #
#  @subpackage  : github                                                   #
#  @access      :                                                          #
#  @paramtype   : token,org                                 #
#  @argument    :                                                          #
#  @description : Get Number ligne of Code in GitHub DevOPS                #
#  @usage : ./github_com.sh <token> <org> and optional <repoName>          #                                                              
#                                                                          #
#                                                                          #
#  @author Emmanuel COLUSSI                                                #
#  @version 1.02                                                           #
#                                                                          #
# Fix isssues                                                              #
#  - If the repository is archived, it will not be analyzed.               #
#  - Pagination issue when over 100 repositories                           #
#  Thanks to @gabrielsoltz for solving these issues and creating a PR      #
#                                                                          #
#**************************************************************************#


if [ $# -ne 2 ]; then
    echo "Usage: `basename $0` <token> <org>"
    exit
fi



# Set Variables user,token,org,BaseAPI
#--------------------------------------------------------------------------------------#
connectionToken=$1
org=$2

BaseAPI="https://api.github.com"

echo "Ok let's go"

#--------------------------------------------------------------------------------------#

# If you use mac osx you have to install the gnu-sed (brew install gnu-sed) then you set in the scripts the variable SED. SED=gsed
# For linux SED=sed
SED="gsed"
i=1
cpt=0


jq_args=".[] | \"\(.name):\(.id):\(.archived)\""
GetAPI="orgs/$org/repos"
# Count Repositories and get pagination
page=1
count=0
while : ; do
    response=$(curl -s --header "Authorization: token $connectionToken" "$BaseAPI/$GetAPI?per_page=100&page=$page")
    repos_count=$(echo "$response" | jq '. | length')
    echo -e "Repository Number :$repos_count"
    if [ "$repos_count" -eq 0 ]; then
        break
    fi

    count=$((count+repos_count))
    page=$((page+1))
done

pages=$page

echo "-----------------------------------------------------------------"
echo "Total repositories: $count (including archived)"
echo "-----------------------------------------------------------------"

# Get List of Repositories : get Name , ID and http_url_to_repo
for ((page=1; page<=pages; page++)); do
    curl -s --header "Authorization: token $connectionToken" "$BaseAPI/$GetAPI?per_page=100&page=$page"|jq -r ''"${jq_args}"''| while IFS=: read -r Name ID Archived;
    do
        if [[ $Name != ".github" && $Archived == "false" ]]; then
            echo $Name
            echo "-----------------------------------------------------------------"
            echo -e "Repository index :$i  Name : $Name id : $ID"
            # Get List of Branches
        
             # Replace space by - in Repository name for created local file
             NameFile=` echo $Name|$SED s/' '/'-'/g`


                # Format Clone URL : cut <https://api.> string
                BaseAPI1="${BaseAPI:12}"

                # Create Command Git clone 
#                git clone https://oauth2:${connectionToken}@$BaseAPI1/$org/$Name --depth 1  $NameFile

                echo -e "downloading from $BaseAPI/repos/$org/$Name/tarball"
                curl -H "Authorization: token $connectionToken" -L $BaseAPI/repos/$org/$Name/tarball > $NameFile.tar.gz
                tar xzf $NameFile.tar.gz
                rm -rf *.tar.gz
            let "i=i+1"
        fi
    done 
done