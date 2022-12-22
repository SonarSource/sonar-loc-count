#!/bin/bash
#set -x
#******************************************************************#
#                                                                  #
#  @project     : LoC Counting bash Scripts                        #
#  @package     :                                                  #
#  @subpackage  : gitlab2                                          #
#  @access      :                                                  #
#  @paramtype   : connectionToken,groupName                        #
#  @argument    :                                                  #
#  @description : Get Number ligne of Code in GitLab DevOPS        #
#  @usage : ./gitlab2_com.sh <token> <groupName>                   #                                                              
#                                                                  #
#                                                                  #
#  @author Emmanuel COLUSSI                                        #
#  @version 1.01                                                   #
#                                                                  #
#******************************************************************#

if [ $# -lt 2 ]; then
    echo "Usage: `basename $0` <token> <groupName>"
    exit
fi

 # Set Variables token, groupName, BaseAPI
connectionToken=$1
groupname=$2
BaseAPI="https://gitlab.com/api/v4"

LISTF=""
LIST=""
i=1

# set command : sed for Mac Osx install gnu-sed : brew install gnu-sed and set SED=gsed
SED="sed"

# Get List of Repositories - List 
curl -s -u $connectionToken: $BaseAPI/groups/$groupname | jq -r '.projects[] | "\(.name):\(.id)"' | while IFS=: read -r Name ID;
do
  echo "-----------------------------------------------------------------"
  printf "Repository Number :$i  Name : $Name id : $ID\n"
# Get List of Branches
   let "i=i+1"
   NameFile=` echo $Name|$SED s/' '/'-'/g`
    
    curl -s -u $connectionToken: $BaseAPI/projects/$ID/repository/branches | jq -r '.[].name' | while read -r BrancheName ;
    do
        LISTF="${NameFile}_${BrancheName}.cloc"
        printf '%s\n' "       Branche Name : $BrancheName"
        # Create Commad Git clone 
        git clone https://oauth2:${connectionToken}@gitlab.com/$groupname/${NameFile}.git --depth 1 --branch $BrancheName $NameFile
        
        # Run Analyse : run cloc on the local repository
       cloc $NameFile --force-lang-def=sonar-lang-defs.txt --report-file=${LISTF} --timeout 0
    
       # Delete Directory projet
        /bin/rm -r $NameFile
       
        gsed -i "1i\Report for project ${Name} / ${BrancheName}\n" $LISTF

    done   
    echo "-----------------------------------------------------------------"
    
     # Combine reports
     echo "Building final report for projet $NameFile : $NameFile.txt "
     ([ `printf *.cloc` != '*.cloc' ] || [ -f '*.txt' ]) &&  for j in `ls -la *.cloc|awk '{print $9}'`; do cat $j >>  $NameFile.txt; done &&  /bin/rm  *.cloc || echo ""

    LISTF=""

done

