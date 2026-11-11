#!/bin/bash
# Count LoC for a file or directory

EXCLUDE=".clocignore"
REPORTDIR="reports"   # matches set_common_variables.sh, which this script doesn't source

source ./require_tools.sh
require_tools cloc

if [ $# -lt 1 ]; then
    echo "Usage: `basename $0` <fileOrDirectory>"
    exit
fi

dir=$1
base="$(basename $dir)"

echo "Counting $dir"
mkdir -p "$REPORTDIR"

excl=()
[ -s "$EXCLUDE" ] && excl=(--exclude-dir="$(tr '\n' ',' < "$EXCLUDE")")
cloc --force-lang-def=sonar-lang-defs.txt --report-file="$REPORTDIR/Report_$base.txt" "${excl[@]}" --timeout 0 --sum-one $dir

exit 0;

