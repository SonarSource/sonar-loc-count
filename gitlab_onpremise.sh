#!/bin/bash
#set -x
#**************************************************************************#
#                                                                          #
#  @project     : LoC Counting bash Scripts                                #
#  @package     :                                                          #
#  @subpackage  : gitlab onpremise                                         #
#  @access      :                                                          #
#  @paramtype   : baseURL,connectionToken,groupName or path_project        #
#  @argument    :                                                          #
#  @description : Get Number ligne of Code in GitLab On-Premise           #
#  @usage : ./gitlab_onpremise.sh <baseURL> <token> <groupName>            #                                                              
#                                                                          #
#                                                                          #
#                                                                          #
#  @version 1.01                                                           #
#                                                                          #
#**************************************************************************#


if [ $# -lt 3 ]; then
    echo "Usage: `basename $0` <baseURL> <token> <groupName|ALL> "
    echo "Example: `basename $0` https://gitlab.example.com mytoken mygroup"
    echo "         `basename $0` https://gitlab.example.com mytoken ALL"
    echo ""
    echo "Use 'ALL' as groupName to discover and process all accessible groups"
    exit
fi

# Set Variables baseURL, token, groupName, Namespace, BaseAPI
# Namespace values : <0> = Browse the groupName - <1> = Browse SubgroupName or Project
#--------------------------------------------------------------------------------------#
baseURL=$1
connectionToken=$2
groupname=$3

# Remove trailing slash from baseURL if present
baseURL=${baseURL%/}

BaseAPI="${baseURL}/api/v4"
#--------------------------------------------------------------------------------------#

source ./set_common_variables.sh

# Function to fetch all accessible groups
fetch_all_groups() {
    local page=1
    local per_page=100
    local all_groups=""
    
    echo "Discovering all accessible groups..."
    
    while :; do
        response=$(curl --silent --header "PRIVATE-TOKEN: $connectionToken" "$BaseAPI/groups?per_page=$per_page&page=$page")
        
        # Check if response is empty or contains no groups
        if [ -z "$response" ] || [ "$response" = "[]" ]; then
            break
        fi
        
        # Extract group names from response
        group_names=$(echo "$response" | jq -r '.[].path' 2>/dev/null)
        
        if [ -z "$group_names" ]; then
            break
        fi
        
        all_groups="$all_groups $group_names"
        ((page++))
    done
    
    echo "$all_groups"
}

# Function to process a single group
process_group() {
    local current_group=$1
    local group_cpt=0
    
    echo "========================================================================="
    echo "Processing Group: $current_group"
    echo "========================================================================="
    
    if [[ "$current_group" =~ .*"/".* ]]; then 
           Namespace=1
        else 
           Namespace=0
    fi

    # Test if request for for 1 Project or more Project in GroupName
         # If you have more than 100 repos Change Value of parameter page=Number_of_page
         # 1 Page = 100 repos max
         # Example for 150 repos :
         #  GetAPI="orgs/$org/repos?per_page=100&page=2"
    if [ $Namespace -eq 1 ]; then
            groupname1=` echo $current_group|$SED s/'\/'/'%2f'/g`
            GetAPI="/projects/$groupname1"
            jq_args="\"\(.name):\(.id):\(.http_url_to_repo)\""

        else  GetAPI="/groups/$current_group/projects?include_subgroups=true"
              jq_args=".[] | \"\(.name):\(.id):\(.http_url_to_repo)\""
    fi

    # Get List of Repositories : get Name , ID and http_url_to_repo
    curl --header "PRIVATE-TOKEN: $connectionToken" $BaseAPI$GetAPI|jq -r ''"${jq_args}"''| while IFS=: read -r Name ID Repourl;

    do
      echo "-----------------------------------------------------------------"
      echo -e "Repository Number :$i  Name : $Name id : $ID"
    # Get List of Branches
       
       # Replace space by - in Repository name for created local file
       NameFile=` echo $Name|$SED s/' '/'-'/g`

       curl  --header "PRIVATE-TOKEN: $connectionToken" $BaseAPI/projects/$ID/repository/branches | jq -r '.[].name' | while read -r BrancheName ;
        do
            # Replace / or space by - in Branche Name for created local file
            BrancheNameF=` echo $BrancheName|$SED s/'\/'/'-'/g|$SED s/' '/'-'/g`
            
            LISTF="${current_group}_${NameFile}_${BrancheNameF}.cloc"
            echo -e "\n       Branche Name : $BrancheName\n"

            # Format Clone URL : cut <https://> or <http://> string
            if [[ "$Repourl" == https://* ]]; then
                CLONE="${Repourl:8}"
            elif [[ "$Repourl" == http://* ]]; then
                CLONE="${Repourl:7}"
            else
                CLONE="$Repourl"
            fi

            # Create Command Git clone with proper authentication for on-premise GitLab
            if [[ "$Repourl" == https://* ]]; then
                git clone https://oauth2:${connectionToken}@$CLONE --depth 1 --branch $BrancheName $NameFile
            elif [[ "$Repourl" == http://* ]]; then
                git clone http://oauth2:${connectionToken}@$CLONE --depth 1 --branch $BrancheName $NameFile
            else
                echo "Warning: Unsupported URL format: $Repourl"
                continue
            fi

            # Run Analyse : run cloc on the local repository
            if [ -s $EXCLUDE ]; then
              cloc $NameFile --force-lang-def=sonar-lang-defs.txt --report-file=${LISTF} --exclude-dir=$(tr '\n' ',' < .clocignore) --timeout 0 --sum-one
            else
               cloc $NameFile --force-lang-def=sonar-lang-defs.txt --report-file=${LISTF} --timeout 0 --sum-one
            fi   
        
           # Delete Directory projet
            /bin/rm -r $NameFile
           
            $SED -i "1i\Report for project ${current_group}/${Name} / ${BrancheName}\n" $LISTF

        done   

    # Generate reports

        echo -e "\nBuilding final report for projet $NameFile : ${current_group}_$NameFile.txt"
        echo "-----------------------------------------------------------------------------------------------------------------------" 

        # BRTAB2 : array with branche Name , The index is number max of cloc 
        # NBTAB1 : array with number max of cloc by branche
      
        ([ `printf ${current_group}_*.cloc` != "${current_group}_*.cloc" ] || [ -f '*.txt' ]) &&  for j in `ls -la ${current_group}_*.cloc 2>/dev/null|awk '{print $9}'`; do  CMD1=`cat $j |grep SUM:|awk '{print $5}'`;BRTAB2["$CMD1"]=${j%?????};NBTAB1+="$CMD1 ";cat $j >>  ${current_group}_$NameFile.txt;done && /bin/rm ${current_group}_*.cloc 2>/dev/null || echo ""

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
                SEA="${current_group}_${NameFile}_"
                MESSAGE02=`echo ${BRTAB2[${INDEX01}]}| $SED s/$SEA/''/g`
        fi      

         printf "The maximum lines of code in the < %s/%s > project is : < %' .f > for the branch : < %s >\n" "${current_group}" "${NameFile}" "${MESSAGE01}" "${MESSAGE02}"
         echo -e "\n---------------------------------------------------------------------------------------------------------------------" >> ${current_group}_$NameFile.txt
         printf "\nThe maximum lines of code in the < %s/%s > project is : < %' .f > for the branch : < %s >\n" "${current_group}" "${NameFile}" "${MESSAGE01}" "${MESSAGE02}" >> ${current_group}_$NameFile.txt
         echo -e "-----------------------------------------------------------------------------------------------------------------------" >> ${current_group}_$NameFile.txt 

        # set Nbr Loc by Project in File cpt.txt
        echo "${INDEX01}" >> $NBCLOC
        
        LISTF=""
        NBTAB1=()
        BRTAB2=()
        let "i=i+1"
        
    done 
}

# Main execution logic
if [ "$groupname" = "ALL" ]; then
    # Discover and process all groups
    groups=$(fetch_all_groups)
    
    if [ -z "$groups" ]; then
        echo "No accessible groups found or error occurred during group discovery."
        exit 1
    fi
    
    echo "Found groups: $groups"
    echo ""
    
    for group in $groups; do
        process_group "$group"
    done
    
else
    # Process single group
    process_group "$groupname"
fi

# Generate Global report
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
