#!/bin/env bash

cd /opt/bin/backup

for file in *.service
do
  sudo cp $file /etc/systemd/system/
  sudo systemctl enable $file
done

for file in *.timer
do
  sudo cp $file /etc/systemd/system/
  sudo systemctl start $file
  sudo systemctl daemon-reload
done

