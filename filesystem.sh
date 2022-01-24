#!/bin/bash
# Count LoC for a file or directory

if [ $# -lt 1 ]; then
    echo "Usage: `basename $0` <fileOrDirectory>"
    exit
fi

dir=$1
base="$(basename $dir)"

echo "Counting $dir"

cloc --force-lang-def=sonar-lang-defs.txt --report-file=$base.lang $dir 

exit 0;

