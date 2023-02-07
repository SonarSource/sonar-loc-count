#!/bin/bash
# set -x
#**************************************************************************#
#                                                                          #
#  @project     : LoC Counting bash Scripts                                #
#  @package     :                                                          #
#  @subpackage  : azure                                                    #
#  @access      :                                                          #
#  @paramtype   : connectionToken,organization, project                    #
#  @argument    :                                                          #
#  @description : Get Number ligne of Code in Azure DevOPS                 #
#  @usage : ./azuredevops.sh <token> <organization> and optional <Project> #                                                              
#                                                                          #
#                                                                          #
#  @author Emmanuel COLUSSI                                                #
#  @version 1.01                                                           #
#                                                                          #
#**************************************************************************#


if [ $# -lt 2 ]; then
    echo "Usage: `basename $0` <token> <organization> optional <projects>"
    exit
fi

# Set Variables token,org,BaseAPI
#--------------------------------------------------------------------------------------#

connectionToken=$1
org=$2
BaseAPI="https://dev.azure.com"

#--------------------------------------------------------------------------------------#

# If you use mac osx you have to install the gnu-sed (brew install gnu-sed) then you set in the scripts the variable SED. SED=gsed
# For linux SED=sed
SED="sed"
i=1
LISTF=""
LIST=""
NBCLOC="cpt.txt"
cpt=0

# Test if request for for 1 Project or more Project

if [ -z ${3} ]; then 
     jq_args=".value[] | \"\(.name):\(.id)\""
     GetAPI="$org/_apis/projects?api-version=7.0"
else 
    jq_args="\"\(.name):\(.id)\""
    GetAPI="$org/_apis/projects/${3}?api-version=7.0"
fi

#  Parse Project
curl -s -u :$connectionToken $BaseAPI/$GetAPI|jq -r ''"${jq_args}"''| while IFS=: read -r Name ID;

do
    echo "--------------------------------------------------------------------------------------------"
    echo -e "Project Number :$i  Name : $Name id : $ID"
    # Get List of Project

    # Replace space by - in Project name for created local file
    NameFile=` echo $Name|$SED s/' '/'-'/g`
    # Replace space by %20 in Project name for Project URL
    name1=` echo $Name|$SED s/' '/'%20'/g`

    #  Parse Project : Get Repositories

     if [ -n ${3} ]; then jq_args=".value[] | \"\(.name):\(.id)\""
     fi
    curl -s -u :$connectionToken "$BaseAPI/$org/$name1/_apis/git/repositories?api-version=7.0" | jq -r ''"${jq_args}"'' | while IFS=: read -r RepoName RepoID;
    do
        # Replace / by - in Repo Name for created local file
        RepoNameF=` echo $RepoName|$SED s/'\/'/'-'/g|$SED s/' '/'-'/g`

         echo "--------------------------------------------------------------------------------------------"
         echo -e "   Repository Name : $RepoName id : $RepoID"
  
          # Get List of Branches
          curl -s -u :$connectionToken "$BaseAPI/$org/$RepoName/_apis/git/repositories/$RepoID/refs?filter=heads/&api-version=7.0" | jq -r '.value[].name' | while read -r BrancheName ;
          do
             # Get Branche Name without path reference
            BrancheNameF1=` echo $BrancheName|$SED s/'refs\/heads\/'/''/g`
            # Replace / by - in Branche Name for created local file
            BrancheNameF=` echo $BrancheNameF1|$SED s/'\/'/'-'/g|$SED s/' '/'-'/g`

            LISTF="${NameFile}_${BrancheNameF}.cloc"
            echo -e "\n       Branche Name : $BrancheNameF1\n"

         # Create Commad Git clone 
            git clone https://$connectionToken@dev.azure.com/$org/$name1/_git/$RepoName --depth 1 --branch $BrancheNameF1 $NameFile

         # Run Analyse : run cloc on the local repository
            cloc $NameFile --force-lang-def=sonar-lang-defs.txt --ignore-case-ext --report-file=${LISTF} --timeout 0
    
         # Delete Directory projet
            /bin/rm -r $NameFile
       
            $SED -i "1i\Report for project ${Name} / ${BrancheName}\n" $LISTF

         done
           
    done
     # Generate reports

        echo -e "\nBuilding final report for projet $NameFile : $NameFile.txt"
        echo "-------------------------------------------------------------------------------------------" 

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
        echo -e "\n-------------------------------------------------------------------------------------------" >> $NameFile.txt
        printf "\nThe maximum lines of code in the < %s > project is : < %' .f > for the branch : < %s >\n" "${NameFile}" "${MESSAGE01}" "${MESSAGE02}" >> $NameFile.txt
        echo -e "-------------------------------------------------------------------------------------------" >> $NameFile.txt 

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
printf "The maximum lines of code on the repository is : < %' .f > result in <global.txt>\n" "${cpt}"
echo -e "\n-------------------------------------------------------------------------------------------"

echo -e "-------------------------------------------------------------------------------------------\n" > global.txt
printf "The maximum lines of code on the repository is : < %' .f > result in <global.txt>\n" "${cpt}" >> global.txt
echo -e "---------------------------------------------------------------------------------------------" >> global.txt







