#!/bin/bash
# Count LoC for a file or directory

EXCLUDE=".clocignore"

if [ $# -lt 1 ]; then
    echo "Usage: `basename $0` <fileOrDirectory>"
    exit
fi

dir=$1
base="$(basename $dir)"

echo "Counting $dir"

if [ -s $EXCLUDE ]; then
 cloc --force-lang-def=sonar-lang-defs.txt --report-file=Report_$base.txt --exclude-dir=$(tr '\n' ',' < .clocignore) --timeout 0 $dir 
else
 cloc --force-lang-def=sonar-lang-defs.txt --report-file=Report_$base.txt --timeout 0 $dir 
fi

exit 0;

