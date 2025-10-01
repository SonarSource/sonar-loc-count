#!/bin/bash
# set -x
#**************************************************************************#
#                                                                          #
#  @project     : LoC Counting bash Scripts                                #
#  @package     :                                                          #
#  @subpackage  : azure                                                    #
#  @access      :                                                          #
#  @paramtype   : server_url, collection, connectionToken, project         #
#  @argument    :                                                          #
#  @description : Get Number of Lines of Code from Azure DevOps Server     #
#  @usage : ./azuredevops_onprem.sh <server_url> <collection> <token> [project]#
#                                                                          #
#  Example:                                                                #
#  ./azuredevops_onprem.sh http://your-tfs-server:8080/tfs DefaultCollection yourPAT #
#                                                                          #
#  @version 1.04                                                           #
#                                                                          #
#**************************************************************************#


if [ $# -lt 3 ]; then
    echo "Usage: `basename $0` <server_url> <collection> <token> [optional_project_name]"
    echo "Example: `basename $0` http://tfs-server/tfs DefaultCollection pat_token"
    exit 1
fi

# Set Variables for on-premise server, collection, token, and optional project
#--------------------------------------------------------------------------------------#

server_url=$1
collection=$2
connectionToken=$3
project_filter=${4} # Optional project name

# Base API URL for on-premise is a combination of server and collection
BaseAPI="${server_url}/${collection}"

# Parse protocol and URL base for constructing the git clone URL with authentication
protocol=$(echo "$BaseAPI" | grep "://" | sed -e's,^\(.*://\).*,\1,g')
url_part=$(echo "$BaseAPI" | sed -e 's,^http://,,g' -e 's,^https://,,g')


#--------------------------------------------------------------------------------------#

source ./set_common_variables.sh

# If a project name is provided, query only that project. Otherwise, query all projects.
if [ -z "${project_filter}" ]; then
     jq_args=".value[] | \"\(.name):\(.id)\""
     GetAPIURL="${BaseAPI}/_apis/projects?api-version=7.0"
else
    jq_args="\"\(.name):\(.id)\""
    GetAPIURL="${BaseAPI}/_apis/projects/${project_filter}?api-version=7.0"
fi

#  Parse Projects
curl -s -k -u :$connectionToken "${GetAPIURL}" | jq -r ''"${jq_args}"''| while IFS=: read -r Name ID;

do
    echo "--------------------------------------------------------------------------------------------"
    echo -e "Project Number :$i  Name : $Name id : $ID"
    # Get List of Project

    # Replace space with '-' for local file names
    NameFile=$(echo "$Name" | $SED 's/ /-/g')
    # Replace space with '%20' for use in URLs
    name1=$(echo "$Name" | $SED 's/ /%20/g')

    #  Parse Project : Get Repositories
    repo_jq_args=".value[] | \"\(.name):\(.id)\""
    curl -s -k -u :$connectionToken "${BaseAPI}/${name1}/_apis/git/repositories?api-version=7.0" | jq -r ''"${repo_jq_args}"'' | while IFS=: read -r RepoName RepoID;
    do
        # Replace '/' and ' ' with '-' in Repo Name for local file names
        RepoNameF=$(echo "$RepoName" | $SED 's/\//-/g' | $SED 's/ /-/g')

         echo "--------------------------------------------------------------------------------------------"
         echo -e "   Repository Name : $RepoName id : $RepoID"

echo "curl -s -k -u :$connectionToken \"${BaseAPI}/${name1}/_apis/git/repositories/${RepoName}/refs?filter=heads/&api-version=7.0\""

          # Get List of Branches
          curl -s -k -u :$connectionToken "${BaseAPI}/${name1}/_apis/git/repositories/${RepoName}/refs?filter=heads/&api-version=7.0" | jq -r '.value[].name' | while read -r BrancheName ;
          do
             # Get clean Branch Name (without 'refs/heads/')
            BrancheNameF1=$(echo "$BrancheName" | $SED 's/refs\/heads\///g')
            # Replace '/' and ' ' with '-' in Branch Name for local file names
            BrancheNameF=$(echo "$BrancheNameF1" | $SED 's/\//-/g' | $SED 's/ /-/g')

            LISTF="${NameFile}_${BrancheNameF}.cloc"
            echo -e "\n       Branch Name : $BrancheNameF1\n"

            
            # Construct the git clone URL for on-premise with embedded PAT for authentication
            CLONE_URL="${protocol}${url_part}/${name1}/_git/${RepoName}"

            TOKEN=$(echo -n "syncuser:${connectionToken}" | base64 --wrap=0)

            echo "TOKEN: $TOKEN"

          echo "git clone -c http.extraheader=\"AUTHORIZATION: Basic ${TOKEN}\" \"${CLONE_URL}\" --depth 1 --branch \"$BrancheNameF1\" \"$NameFile\""


            # Create Command Git clone
            git clone -c http.extraheader="AUTHORIZATION: Basic ${TOKEN}" "${CLONE_URL}" --depth 1 --branch "$BrancheNameF1" "$NameFile"

             # Run Analyse : run cloc on the local repository
             if [ -s "$EXCLUDE" ]; then
                cloc "$NameFile" --force-lang-def=sonar-lang-defs.txt --ignore-case-ext --report-file=${LISTF} --exclude-dir=$(tr '\n' ',' < .clocignore)  --timeout 0 --sum-one
             else
                cloc "$NameFile" --force-lang-def=sonar-lang-defs.txt --ignore-case-ext --report-file=${LISTF} --timeout 0 --sum-one
            fi

             # Delete Directory project
                /bin/rm -rf "$NameFile"

            $SED -i "1i\Report for project ${Name} / ${BrancheName}\n" "$LISTF"

         done

    done
     # Generate reports

        echo -e "\nBuilding final report for project $NameFile : $NameFile.txt"
        echo "-------------------------------------------------------------------------------------------"

        # BRTAB2 : array with branch Name , The index is number max of cloc
        # NBTAB1 : array with number max of cloc by branch

        if ls *.cloc 1> /dev/null 2>&1; then
            for j in *.cloc; do
                CMD1=$(cat "$j" | grep SUM: | awk '{print $5}')
                BRTAB2["$CMD1"]=${j%.cloc}
                NBTAB1+=("$CMD1")
                cat "$j" >> "$NameFile.txt"
            done
            /bin/rm *.cloc
        fi


        # Find the max LoC for the project
        if [ ${#NBTAB1[@]} -gt 0 ]; then
            IFS=$'\n' sorted=($(sort -nr <<<"${NBTAB1[*]}"))
            unset IFS
            INDEX01=${sorted[0]}
        else
            INDEX01=""
        fi


        if [ -z "$INDEX01" ]; then
                MESSAGE01="0"
                MESSAGE02="No"
                INDEX01=0

            else
                MESSAGE01="$INDEX01"
                SEA="${NameFile}_"
                MESSAGE02=$(echo "${BRTAB2[${INDEX01}]}" | $SED "s/$SEA//g")
        fi

        printf "The maximum lines of code in the < %s > project is : < %' .f > for the branch : < %s >\n" "${NameFile}" "${MESSAGE01}" "${MESSAGE02}"
        echo -e "\n-------------------------------------------------------------------------------------------" >> "$NameFile.txt"
        printf "\nThe maximum lines of code in the < %s > project is : < %' .f > for the branch : < %s >\n" "${NameFile}" "${MESSAGE01}" "${MESSAGE02}" >> "$NameFile.txt"
        echo -e "-------------------------------------------------------------------------------------------" >> "$NameFile.txt"

        # set Nbr Loc by Project in File cpt.txt
        echo "${INDEX01}" >> "$NBCLOC"

        LISTF=""
        NBTAB1=()
        declare -A BRTAB2=() # Re-declare array for next iteration
        let "i=i+1"

done

# Generate Global report
cpt=0
if [ -f "$NBCLOC" ]; then
    while read line
    do
       cpt=$(expr $cpt + $line)
    done < "$NBCLOC"

    /bin/rm "$NBCLOC"
fi


echo -e "\n-------------------------------------------------------------------------------------------"
printf "The total maximum lines of code across all projects is : < %' .f >. See Report_global.txt for details.\n" "${cpt}"
echo -e "-------------------------------------------------------------------------------------------"

echo -e "-------------------------------------------------------------------------------------------\n" > Report_global.txt
printf "The total maximum lines of code across all projects is : < %' .f >.\n" "${cpt}" >> Report_global.txt
echo -e "---------------------------------------------------------------------------------------------" >> Report_global.txt
