#!/bin/env bash

SCRIPTDIR=/opt/bin/backup
file=$1
while read -r line; do
    [[ "$line" =~ ^#.*$ ]] && continue
    ${SCRIPTDIR}/backup ${line}
done < "$file"
echo "Alle jobs afgerond"