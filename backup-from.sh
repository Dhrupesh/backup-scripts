#!/bin/env bash

SCRIPTDIR=/opt/bin/backup
file=$1
while read -r line; do
    [[ "$line" =~ ^#.*$ ]] && continue
    ${SCRIPTDIR}/backup.sh ${line}
done < "$file"
echo "Alle jobs afgerond"