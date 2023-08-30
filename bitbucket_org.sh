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
#  @author Emmanuel COLUSSI                                                         #
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


# Get List of Repositories : get Name , ID and http_url_to_repo
curl -s -u $user:$connectionToken $BaseAPI/$GetAPI|jq -r ''"${jq_args}"''| while IFS=: read -r Name UUID;

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

            LISTF="${NameFile}_${BrancheNameF}.cloc"
            
            echo -e "\n       Branche Name : $BrancheNameF1\n"

            # Create Commad Git clone 
            git clone  https://$user:${connectionToken}@$BaseAPI1/$wks/$name1 --depth 1 --branch $BrancheNameF1 $NameFile

            # Run Analyse : run cloc on the local repository
            if [ -s $EXCLUDE ]; then
              cloc $NameFile --force-lang-def=sonar-lang-defs.txt --report-file=${LISTF} --exclude-dir=$(tr '\n' ',' < .clocignore) --timeout 0 --sum-one
            else
               cloc $NameFile --force-lang-def=sonar-lang-defs.txt --report-file=${LISTF} --timeout 0 --sum-one
            fi   
        
            # Delete Directory projet
            /bin/rm -r $NameFile
           
            $SED -i "1i\Report for project ${Name} / ${BrancheName}\n" $LISTF

            if [ ! -z ${5} ]; then
                break
            fi
        done
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
