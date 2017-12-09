#!/bin/env bash

NFS_MOUNT=/mnt/prod-NSM
CONTAINER_STORE=/mnt/store

FROMHOST=$1
FROMINSTANCE=$2
TOSERVER=$3
DB=$4
PG_PORT=$5
PG_VERSION=$6
SSH_USER=$7
TOINSTANCE=$8
FILESTORE_PATH=$9

BACKUPPATH=$FROMHOST/$FROMINSTANCE
DB_BACKUPPATH_IN=$CONTAINER_STORE/$BACKUPPATH/db/$PG_VERSION
DB_BACKUPPATH_OUT=$NFS_MOUNT/$BACKUPPATH/db/$PG_VERSION

# SCRIPTPATH=/mnt/array2/Storage/OpenERP/scripts
# BACKUPPATH=/mnt/array2/Storage/OpenERP/${FROMSERVER}-OPENERP
# EXCLUDES="filestore"
# OPTS="--exclude $EXCLUDES  -a --delete --log-file=${BACKUPPATH}/log/rsync_restore.log ${BACKUPPATH}/openerp"
FSOPTS="-a --delete --log-file=${BACKUPPATH}/log/rsync_restore.log ${BACKUPPATH}/root/filestore/$DB"

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
#echo "odoo sources ook herstellen?"
#read B
#if [ $B = "y" ]
#then
#echo "odoo sources worden gerestored exclusief de filestores"
#/usr/local/bin/rsync $OPTS root@${TOSERVER}:/home/
#fi
echo "filestore/$DB herstellen?"
read C
if [ $C = "y" ]
then
/usr/local/bin/rsync $FSOPTS root@${TOSERVER}:${TOINSTANCE}/filestore/
fi
echo "klaar!!"