#!/bin/bash
#set -x
#***********************************************************************************#
#                                                                                   #
#  @project     : LoC Counting bash Scripts                                         #
#  @package     :                                                                   #
#  @subpackage  : bitbucket                                                         #
#  @access      :                                                                   #
#  @paramtype   : user token,workspace ,reponame                                    #
#  @argument    :                                                                   #
#  @description : Get Number ligne of Code in Bitbucket DevOPS                      #
#  @usage : ./bitbucket_org.sh <user> <token> <workspace> and optional <repoName>   #                                                              
#                                                                                   #
#                                                                                   #
#                                                                                   #
#  @version 1.01                                                                    #
#                                                                                   #
#***********************************************************************************#


if [ $# -lt 3 ]; then
    echo "Usage: `basename $0` <user> <token> <workspace> and optional <repoName>"
    exit
fi

# Set Variables user,token,org,BaseAPI
#--------------------------------------------------------------------------------------#
user=$1
connectionToken=$2
wks=$3

BaseAPI="https://api.bitbucket.org/2.0"
BaseAPI1="bitbucket.org"
#--------------------------------------------------------------------------------------#

source ./set_common_variables.sh

# Clear the work dir so leftovers from an interrupted run don't get counted.
/bin/rm -rf "$WORKDIR"
mkdir -p "$WORKDIR" "$REPORTDIR"
# Overrides the common NBCLOC (cpt.txt) to keep the counter out of the repo root
NBCLOC="$WORKDIR/cpt.txt"
GLOBALREPORT="$REPORTDIR/Report_global.txt"

# cloc exclusions, read once rather than per branch
excl=()
[ -s "$EXCLUDE" ] && excl=(--exclude-dir="$(tr '\n' ',' < "$EXCLUDE")")

# Initialize the counter file
> $NBCLOC

# Git over HTTPS with an Atlassian API token uses a fixed username, sent here as a header.
# Note: like the curl -u calls, this puts the (base64-encoded) token in the process's
# arguments, so other users on the same machine can see it with ps.
gitAuthHeader="Authorization: Basic $(printf 'x-bitbucket-api-token-auth:%s' "$connectionToken" | base64 | tr -d '\n')"

# Test if request for for 1 Repo or more Repo

if [ -z ${4} ]; then 
     jq_args=".values[] | \"\(.slug):\(.uuid)\""
     # If you have more than 100 repos Change Value of parameter page=Number_of_page
     # 1 Page = 100 repos max
     # Example for 150 repos :
     #  GetAPI="orgs/$org/repos?pagelen=100&page=2"
     GetAPI="repositories/$wks?pagelen=100&page=1"
else 
    jq_args="\"\(.slug):\(.uuid)\"" 
    GetAPI="repositories/$wks/$4"
fi

repoNextUrl=$BaseAPI/$GetAPI

while [ ! -z $repoNextUrl ]
do

    # Get List of Repositories : get Name , ID and http_url_to_repo
    echo "Next URL is: $repoNextUrl"
    GETREPOOUT=$(curl -s -u $user:$connectionToken $repoNextUrl)
    repoNextUrl=$(echo $GETREPOOUT | jq -r '.next')
    infoTotal=$(echo $GETREPOOUT | jq -r '.size')
    infoPage=$(echo $GETREPOOUT | jq -r '.page')
    if [ "$infoTotal" != "null" ] && [ ! -z "$infoTotal" ]; then
        echo "Processing page $infoPage of $(($infoTotal/$pagelen))"
    else
        echo "Processing page $infoPage"
    fi
    echo $GETREPOOUT|jq -r ''"${jq_args}"''| while IFS=: read -r Name UUID;
    
    do
        echo "-----------------------------------------------------------------------------------------------------------------------" 
        echo -e "Repository Number :$i  Name : $Name uuid : $UUID"
        # Get List of Branches
    
        # Replace space by - in Repository name for created local file
        NameFile=` echo $Name|$SED s/' '/'-'/g`
        # Replace space by %20 in Repository name for Repository URL
        name1=` echo $Name|$SED s/' '/'%20'/g`
    
        nextUrl="${BaseAPI}/repositories/$wks/$Name/refs/branches"
        while [ ! -z $nextUrl ]
        do
            branchesJson=$(curl -s -u $user:$connectionToken $nextUrl)
            
            if [ -z ${5} ]; then
                nextUrl=$(echo $branchesJson | jq -r ".next")
            else
                unset nextUrl
            fi
            
            echo $branchesJson | jq -r '.values[].name' | while read -r BrancheName ;
            do
                if [ ! -z ${5} ]; then
                    BrancheName="${5}"
                fi
                
                # Get Branche Name without path reference
                BrancheNameF1=$(echo $BrancheName|$SED s/'refs\/heads\/'/''/g)
                # Replace / by - in Branche Name for created local file
                BrancheNameF=$(echo $BrancheNameF1|$SED s/'\/'/'-'/g|$SED s/' '/'-'/g)
    
                LISTF="$WORKDIR/${NameFile}_${BrancheNameF}.cloc"
                CloneDir="$WORKDIR/$NameFile"
                
                echo -e "\n       Branche Name : $BrancheNameF1\n"
    
                # Create Commad Git clone 
                git -c http.extraHeader="$gitAuthHeader" clone https://$BaseAPI1/$wks/$name1 --depth 1 --branch $BrancheNameF1 "$CloneDir"
    
                # Run Analyse : run cloc on the local repository
                cloc "$CloneDir" --force-lang-def=sonar-lang-defs.txt --report-file="$LISTF" "${excl[@]}" --timeout 0 --sum-one
            
                # Delete Directory projet
                /bin/rm -rf "$CloneDir"
               
                $SED -i "1i\Report for project ${Name} / ${BrancheName}\n" $LISTF
    
                if [ ! -z ${5} ]; then
                    break
                fi
            done
        done
         # Generate reports
    
            REPORT="$REPORTDIR/$NameFile.txt"
            echo -e "\nBuilding final report for projet $NameFile : $REPORT"
            echo "-----------------------------------------------------------------------------------------------------------------------" 
    
            # BRTAB2 : array with branche Name , The index is number max of cloc 
            # NBTAB1 : array with number max of cloc by branche
      
            # Start each repo's report fresh rather than appending to the previous run's
            > "$REPORT"
            for j in "$WORKDIR"/*.cloc; do
                [ -e "$j" ] || continue
                CMD1=$(grep SUM: "$j" | awk '{print $5}')
                b=${j##*/}
                BRTAB2["$CMD1"]=${b%.cloc}
                NBTAB1+="$CMD1 "
                cat "$j" >> "$REPORT"
            done
            /bin/rm -f "$WORKDIR"/*.cloc
    
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
            {
                echo -e "\n---------------------------------------------------------------------------------------------------------------------"
                printf "\nThe maximum lines of code in the < %s > project is : < %' .f > for the branch : < %s >\n" "${NameFile}" "${MESSAGE01}" "${MESSAGE02}"
                echo -e "-----------------------------------------------------------------------------------------------------------------------"
            } >> "$REPORT"
    
            # set Nbr Loc by Project in File cpt.txt
            echo "${INDEX01}" >> $NBCLOC
        
            LISTF=""
            NBTAB1=()
            BRTAB2=()
            let "i=i+1"
        
    done 
done

# Generate Gobal report
while read line  
do   
   cpt=$(expr $cpt + $line)
done < $NBCLOC

/bin/rm $NBCLOC

echo -e "\n-------------------------------------------------------------------------------------------"
printf "The maximum lines of code on the repository is : < %' .f > result in <%s>\n" "${cpt}" "$GLOBALREPORT"
echo -e "\n-------------------------------------------------------------------------------------------"

{
    echo -e "-------------------------------------------------------------------------------------------\n"
    printf "The maximum lines of code on the repository is : < %' .f > result in <%s>\n" "${cpt}" "$GLOBALREPORT"
    echo -e "---------------------------------------------------------------------------------------------"
} > "$GLOBALREPORT"
