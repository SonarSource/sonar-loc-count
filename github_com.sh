#!/bin/bash
#set -x
#**************************************************************************#
#                                                                          #
#  @project     : LoC Counting bash Scripts                                #
#  @package     :                                                          #
#  @subpackage  : github                                                   #
#  @access      :                                                          #
#  @paramtype   : user,token,org ,reponame                                 #
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


if [ $# -lt 3 ]; then
    echo "Usage: `basename $0` <user> <token> <org> and optional <repoName>"
    exit
fi

# Set Variables user,token,org,BaseAPI
#--------------------------------------------------------------------------------------#
user=$1
connectionToken=$2
org=$3

BaseAPI="https://api.github.com"

#--------------------------------------------------------------------------------------#

# If you use mac osx you have to install the gnu-sed (brew install gnu-sed) then you set in the scripts the variable SED. SED=gsed
# For linux SED=sed
SED="gsed"
i=1
LISTF=""
LIST=""
NBCLOC="cpt.txt"
cpt=0
EXCLUDE=".clocignore"

# Test if request for 1 Repo or more Repo

if [ -z ${4} ]; then 
    jq_args=".[] | \"\(.name):\(.id):\(.archived)\""
    GetAPI="orgs/$org/repos"
    # Count Repositories and get pagination
    page=1
    count=0
    while : ; do
        response=$(curl -s -u $user:$connectionToken "$BaseAPI/$GetAPI?per_page=100&page=$page")
        repos_count=$(echo "$response" | jq '. | length')
        
        if [ "$repos_count" -eq 0 ]; then
            break
        fi

        count=$((count+repos_count))
        page=$((page+1))
    done
    
    pages=$page
else 
    jq_args="\"\(.name):\(.id):\(.archived)\"" 
    GetAPI="repos/$org/$4"
    pages=1
    count=1
fi

echo "-----------------------------------------------------------------"
echo "Total repositories: $count (including archived)"
echo "-----------------------------------------------------------------"

# Get List of Repositories : get Name , ID and http_url_to_repo
for ((page=1; page<=pages; page++)); do
    curl -s -u $user:$connectionToken "$BaseAPI/$GetAPI?per_page=100&page=$page"|jq -r ''"${jq_args}"''| while IFS=: read -r Name ID Archived;
    do
        if [[ $Name != ".github" && $Archived == "false" ]]; then
            echo $Name
            echo "-----------------------------------------------------------------"
            echo -e "Repository Number :$i  Name : $Name id : $ID"
            # Get List of Branches
        
             # Replace space by - in Repository name for created local file
             NameFile=` echo $Name|$SED s/' '/'-'/g`

             curl -s -u $connectionToken: $BaseAPI/repos/$org/$Name/branches | jq -r '.[].name' | while read -r BrancheName ;
             do
                # Replace / or space by - in Branche Name for created local file
                BrancheNameF=` echo $BrancheName|$SED s/'\/'/'-'/g|$SED s/' '/'-'/g`

                LISTF="${NameFile}_${BrancheNameF}.cloc"
                echo -e "\n       Branche Name : $BrancheName\n"

                # Format Clone URL : cut <https://api.> string
                BaseAPI1="${BaseAPI:12}"

                # Create Commad Git clone 
                git clone https://oauth2:${connectionToken}@$BaseAPI1/$org/$Name --depth 1 --branch $BrancheName $NameFile

                 # Run Analyse : run cloc on the local repository
                 if [ -s $EXCLUDE ]; then
                   cloc $NameFile --force-lang-def=sonar-lang-defs.txt --report-file=${LISTF} --exclude-dir=$(tr '\n' ',' < .clocignore) --timeout 0 --sum-one
                 else
                     cloc $NameFile --force-lang-def=sonar-lang-defs.txt --report-file=${LISTF} --timeout 0 --sum-one
                 fi    
        
                # Delete Directory projet
                 /bin/rm -r $NameFile
        
                $SED -i "1i\Report for project ${Name} / ${BrancheName}\n" $LISTF

             done

             # Generate reports

            echo -e "\nBuilding final report for projet $NameFile : $NameFile.txt"
            echo "-----------------------------------------------------------------------------------------------------------------------" 

            # BRTAB2 : array with branche Name , The index is number max of cloc 
            # NBTAB1 : array with number max of cloc by branche
    
            ([ `printf *.cloc` != '*.cloc' ] || [ -f '*.txt' ]) &&  for j in `ls -la *.cloc|awk '{print $9}'`; do  CMD1=`cat $j |grep SUM:|awk '{print $5}'`;BRTAB2["$CMD1"]=${j%?????};NBTAB1+="$CMD1 ";cat $j >>  $NameFile.txt;done && /bin/rm *.cloc || echo ""

            # Find 
            IFS=' ' NBRCLOC=( $NBTAB1 )
            IFS=$'\n' sorted=( $(sort -nr <<<"${NBRCLOC[*]}") )
            INDEX01=${sorted[0]}

            if [ -z "$INDEX01" ]; then 
                    MESSAGE01="0"
                    MESSAGE02="No"
                    INDEX01=0  

                else 
                    MESSAGE01="$INDEX01"
                    SEA="${NameFile}_"
                    MESSAGE02=`echo ${BRTAB2[${INDEX01}]}| $SED s/$SEA/''/g`
            fi      

            printf "The maximum lines of code in the < %s > project is : < %' .f > for the branch : < %s >\n" "${NameFile}" "${MESSAGE01}" "${MESSAGE02}"
            echo -e "\n---------------------------------------------------------------------------------------------------------------------" >> $NameFile.txt
            printf "\nThe maximum lines of code in the < %s > project is : < %' .f > for the branch : < %s >\n" "${NameFile}" "${MESSAGE01}" "${MESSAGE02}" >> $NameFile.txt
            echo -e "-----------------------------------------------------------------------------------------------------------------------" >> $NameFile.txt 

            # set Nbr Loc by Project in File cpt.txt
            echo "${INDEX01}" >> $NBCLOC
        
            LISTF=""
            NBTAB1=()
            BRTAB2=()
            let "i=i+1"
        fi
    done 
done

# Generate Gobal report
while read line  
do   
   cpt=$(expr $cpt + $line)
done < $NBCLOC

/bin/rm $NBCLOC

echo -e "\n-------------------------------------------------------------------------------------------"
printf "The maximum lines of code on the repository is : < %' .f > result in <Report_global.txt>\n" "${cpt}"
echo -e "\n-------------------------------------------------------------------------------------------"

echo -e "-------------------------------------------------------------------------------------------\n" > Report_global.txt
printf "The maximum lines of code on the repository is : < %' .f > result in <Report_global.txt>\n" "${cpt}" >> Report_global.txt
echo -e "---------------------------------------------------------------------------------------------" >> Report_global.txt
