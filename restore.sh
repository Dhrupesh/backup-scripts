#!/bin/env bash

NFS_MOUNT=/mnt/prod-NSM
CONTAINER_STORE=/mnt/store

# FROMHOST=$1
# FROMINSTANCE=$2
# TOSERVER=$3
# DB=$4
# PG_PORT=$5
# PG_VERSION=$6
# SSH_USER=$7
# TOINSTANCE=$8
# FILESTORE_PATH=$9


echo "Which Host is the Source?"
read FROMHOST
echo "Which Instance is the Source?"
read FROMINSTANCE
echo "Which Host is the Destination?"
read TOSERVER
echo "Which Database?"
read DB
echo "Which Port runs Postgres destination?"
read PG_PORT
echo "Which Postgres Version?"
read PG_VERSION
echo "Which ssh-user has destination?"
read SSH_USER
echo "Which location of filestore at source? \".filestore\" or \"data\"?"
read FILESTORE
echo "What is the full path in destination of the filestore (not incuding "filestore" at the end)?"
read FILESTORE_PATH

BACKUPPATH=$FROMHOST/$FROMINSTANCE
DB_BACKUPPATH_IN=$CONTAINER_STORE/$BACKUPPATH/db/$PG_VERSION
DB_BACKUPPATH_OUT=$NFS_MOUNT/$BACKUPPATH/db/$PG_VERSION

FSOPTS="-a --delete --log-file=${NFS_MOUNT}/${BACKUPPATH}/log/rsync_restore.log ${NFS_MOUNT}/${BACKUPPATH}/root/${FILESTORE}/filestore/$DB"

echo "FROMHOST=$FROMHOST FROMINSTANCE=$FROMINSTANCE TOSERVER=$TOSERVER TOINSTANCE=$TOINSTANCE DB=$DB PG_PORT=$PG_PORT PG_VERSION=$PG_VERSION SSH_USER=$SSH_USER DB_BACKUPPATH_IN=$DB_BACKUPPATH_IN"
echo "DB $DB verwijderen en backup terugzetten?(y/n)"
read A
if [ $A = "y" ]
then
docker run -v $NFS_MOUNT:$CONTAINER_STORE --rm postgres:${PG_VERSION} dropdb -U postgres -h $TOSERVER -p $PG_PORT $DB
echo "DB $DB verwijderd. $DB.dump wordt nu geïmporteerd"
docker run -v $NFS_MOUNT:$CONTAINER_STORE --rm postgres:${PG_VERSION} pg_restore -U postgres -h $TOSERVER -p $PG_PORT -C -j 4 -d postgres ${DB_BACKUPPATH_IN}/$DB.dump
echo "$DB is hersteld"
fi

echo "filestore/$DB herstellen?"
read B
if [ $B = "y" ]
then
echo "rsync $FSOPTS ${SSH_USER}@${TOSERVER}:${FILESTORE_PATH}/filestore/"
fi
echo "GOED?"
read C
if [ $C = "y" ]
then
rsync $FSOPTS --rsync-path="sudo rsync" -e "ssh -i ~/.ssh/kp002.pem" ${SSH_USER}@${TOSERVER}:${FILESTORE_PATH}/filestore/
fi
echo "klaar!!"