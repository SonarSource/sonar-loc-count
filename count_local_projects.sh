#!/bin/bash
#set -x
#**************************************************************************#
#                                                                          #
#  @project     : LoC Counting bash Scripts                                #
#  @package     :                                                          #
#  @subpackage  : None                                                     #
#  @access      :                                                          #
#  @paramtype   : None                                                     #
#  @argument    :                                                          #
#  @description : Get Number ligne of Code from sub-folders, 1 per project #
#  @usage : ./ ount_local_projects.sh                                      #                                                              
#                                                                          #
#                                                                          #
#  @author Sylvain Combe                                                   #
#  @version 1.0                                                            #
#                                                                          #
# Fixed isssues                                                            # 
#**************************************************************************#


if [ $# -ne 0 ]; then
    echo "Usage: `basename $0`"
    exit
fi

# Set Variables user,token,org,BaseAPI
#--------------------------------------------------------------------------------------#


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

for file in */ ; do 
  if [[ -d "$file" ]]; then
    file="${file%/}"
    LISTF="$file.cloc"
    echo -e "Counting LOCs from the $file directory in $LISTF";


    # Run Analyse : run cloc on the local repository
    if [ -s $EXCLUDE ]; then
      cloc $file --force-lang-def=sonar-lang-defs.txt --report-file=${LISTF} --exclude-dir=$(tr '\n' ',' < .clocignore) --timeout 0 --sum-one 
    else
      cloc $file --force-lang-def=sonar-lang-defs.txt --report-file=${LISTF} --timeout 0 --sum-one
    fi
  fi; 
done

cloc --force-lang-def=sonar-lang-defs.txt  --sum-reports *.cloc
