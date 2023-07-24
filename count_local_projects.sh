#!/bin/bash
#set -x
#**************************************************************************#
#                                                                          #
#  @project     : LoC Counting bash Scripts                                #
#  @package     :                                                          #
#  @subpackage  : None                                                     #
#  @access      :                                                          #
#  @paramtype   : Number of days to filter out inactive projects           #
#  @argument    : max-age-in-days                                                         #
#  @description : Get Number ligne of Code from sub-folders, 1 per project #
#  @usage : ./count_local_projects.sh <nbDays>                               #                                                              
#                                                                          #
#                                                                          #
#  @author Sylvain Combe                                                   #
#  @version 1.0                                                            #
#                                                                          #
# Fixed isssues                                                            # 
#**************************************************************************#


if [ $# -ne 1 ]; then
    echo "Usage: `basename $0` <nbDays>"
    exit
fi
nbDays=$1
# replace with gtouch on MacOS (coreutils needed)
gtouch -d "$nbDays days ago" $nbDays.ago



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
    if [ $file -ot "$nbDays.ago" ]; then
      echo -e "Repo $file not commited to on its main branch since more than $nbDays"; 
      continue;
    fi

    file="${file%/}"
    LISTF="$file.cloc"
    echo -e "Counting LOCs from the $file directory in $LISTF";


    # Run Analyse : run cloc on the local repository
    if [ -s $EXCLUDE ]; then
      cloc $file --force-lang-def=sonar-lang-defs.txt --report-file=${LISTF} --exclude-dir=$(tr '\n' ',' < .clocignore) --timeout 0 --sum-one --ignored=${LISTF}.ignored
    else
      cloc $file --force-lang-def=sonar-lang-defs.txt --report-file=${LISTF} --timeout 0 --sum-one
    fi
  fi; 
done

echo -e "$0 $@"  > general-script-output.txt
echo -e "#######################" >> general-script-output.txt
cloc --force-lang-def=sonar-lang-defs.txt  --sum-reports *.cloc >> general-script-output.txt
cat general-script-output.txt

if [[ ! -d "outputs" ]]; then
  mkdir outputs
fi
mv *.cloc outputs
mv $nbDays.ago outputs
mv general-script-output.txt outputs
