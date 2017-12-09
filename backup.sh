#!/bin/bash
#
#
#
NFS_MOUNT=/mnt/prod-NSM
CONTAINER_STORE=/mnt/store
INSTANCE=$1
HOST=$2
INST_PATH=$3
SSH_USER=$4
PG_PORT=$5
DBS=$6
PG_VERSION=$7

BACKUPPATH=$HOST/$INSTANCE
DB_BACKUPPATH_IN=$CONTAINER_STORE/$BACKUPPATH/db/$PG_VERSION
DB_BACKUPPATH_OUT=$NFS_MOUNT/$BACKUPPATH/db/$PG_VERSION

echo "INSTANCE=$INSTANCE HOST=$HOST INST_PATH=$INST_PATH SSH_USER=$SSH_USER PG_PORT=$PG_PORT DBS=$DBS PG_VERSION=$PG_VERSION DB_BACKUPPATH_IN=$DB_BACKUPPATH_IN"

if ! [[ $PG_PORT = "" ]];
then
    IFS=","
    for DB in $DBS
        do
        if [ ! -e "$DB_BACKUPPATH_OUT" ]; then
            mkdir -p "$DB_BACKUPPATH_OUT"
        fi
        docker run -v $NFS_MOUNT:$CONTAINER_STORE --rm postgres:${PG_VERSION} pg_dump -b -FC -U postgres -h $HOST -p $PG_PORT -f $DB_BACKUPPATH_IN/$DB.dump $DB
        done
fi
if [ ! -e "$NFS_MOUNT/$BACKUPPATH/log" ]; then
    mkdir -p "$NFS_MOUNT/$BACKUPPATH/log"
    touch "$NFS_MOUNT/$BACKUPPATH/log/rsync_client.log"
fi
if [ ! -e "$NFS_MOUNT/$HOST/log" ]; then
    mkdir -p "$NFS_MOUNT/$HOST/log"
    touch $NFS_MOUNT/$HOST/log/rsync_client.log
fi
if [ ! -e "$NFS_MOUNT/$BACKUPPATH/log/rsync_client.log" ]; then
    touch "$NFS_MOUNT/$BACKUPPATH/log/rsync_client.log"
fi
if [ ! -e "$NFS_MOUNT/$HOST/log/rsync_client.log" ]; then
    touch $NFS_MOUNT/$HOST/log/rsync_client.log
fi


rsync -av --delete --log-file=$NFS_MOUNT/$BACKUPPATH/log/rsync_client.log --rsync-path="sudo rsync" -e "ssh -i ~/.ssh/kp002.pem" $SSH_USER@$HOST:$INST_PATH/ $NFS_MOUNT/$HOST/$INSTANCE/root/
# rsync -av --delete --log-file=$NFS_MOUNT/$HOST/log/rsync_client.log --rsync-path="sudo rsync" -e "ssh -i ~/.ssh/kp002.pem" $SSH_USER@$HOST:$INST_PATH/ $NFS_MOUNT/$HOST/$INSTANCE/
