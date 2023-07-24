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
#  @usage : ./make_sum_only.sh <nbDays>                               #                                                              
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
touch -d "$nbDays days ago" $nbDays.ago



#--------------------------------------------------------------------------------------#

LISTF=""
LIST=""
EXCLUDE=".clocignore"

if [[ ! -d "cloc-obsolete-repos" ]]; then
  mkdir cloc-obsolete-repos
fi

for file in */ ; do 
  if [[ -d "$file" ]]; then
    file="${file%/}"
    LISTF="$file.cloc"

    if [ $file -ot "$nbDays.ago" ]; then
      echo -e "Repo $file not committed to on its main branch since more than $nbDays"; 
      mv $LISTF cloc-obsolete-repos
      continue;
    fi

    if [[ ! -e "$LISTF" ]]; then
      echo -e "Error cloc file $LISTF not found, ignored";
      continue;
    fi
  fi
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
