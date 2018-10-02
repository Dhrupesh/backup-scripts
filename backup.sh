#!/bin/env bash
#
# backup script based on zerotier/zerotier-containerized:latest and the official
# postgres docker images in the versions to be backupped and/or restored, currently 9.1, 9.3, 9.5 and 9.6
#
NFS_MOUNT=/mnt/prod-NSM
CONTAINER_STORE=/mnt/store
INSTANCE=$1
HOST=$2
INST_PATH=$3
SSH_USER=$4
PG_PORT=$5
PG_VERSION=$7

BACKUPPATH=$HOST/$INSTANCE
DB_BACKUPPATH_IN=$CONTAINER_STORE/$BACKUPPATH/db/$PG_VERSION
DB_BACKUPPATH_OUT=$NFS_MOUNT/$BACKUPPATH/db/$PG_VERSION

function error_mail {
    echo "email versturen"
}

function check_exec_ok {
    if [[ $?  -eq 0 ]]; then
        echo "$1"
        else
        echo "$2"
        error_mail
    fi
} 

echo "INSTANCE=$INSTANCE HOST=$HOST INST_PATH=$INST_PATH SSH_USER=$SSH_USER PG_PORT=$PG_PORT PG_VERSION=$PG_VERSION DB_BACKUPPATH_IN=$DB_BACKUPPATH_IN"

if ! [[ $PG_PORT = "" ]];
then
    RESULT=$(docker run -v /etc/hosts:/etc/hosts:ro --rm postgres:${PG_VERSION} psql -U postgres -h $HOST -p $PG_PORT -t -c "SELECT datname FROM pg_database where datname not in ('template0', 'template1', 'postgres')")
    IFS=" "
    for DB in $RESULT
        do
        if [ ! -e "$DB_BACKUPPATH_OUT" ]; then
            mkdir -p "$DB_BACKUPPATH_OUT"
        fi
        docker run -v $NFS_MOUNT:$CONTAINER_STORE -v /etc/hosts:/etc/hosts:ro --rm postgres:${PG_VERSION} pg_dump -b -FC -U postgres -h $HOST -p $PG_PORT -f $DB_BACKUPPATH_IN/$DB.dump $DB
        check_exec_ok "db-dump $DB succesvol" "db-dump $DB NIET succesvol"
        done
fi
echo "Start synchronisatie van instance root"
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


sudo rsync -az --delete --copy-unsafe-links --log-file=$NFS_MOUNT/$BACKUPPATH/log/rsync_client.log --rsync-path="sudo rsync" -e "ssh -i ~/.ssh/kp002.pem" $SSH_USER@$HOST:$INST_PATH/ $NFS_MOUNT/$HOST/$INSTANCE/root/
check_exec_ok "root van $HOST, $INSTANCE gesynchroniseerd" "root van $HOST, $INSTANCE NIET gesynchroniseerd"
echo "backup-job klaar!"