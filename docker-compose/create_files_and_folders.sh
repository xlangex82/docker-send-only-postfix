#!/usr/bin/env bash

# usage: sudo ./data/create_files_and_folders.sh /docker/postfix-relay-server/data/
# to create folder for volumes on this path
#     volumes:
#      - "/docker/postfix-relay-server/data/config/rsyslog/rsyslog.conf:/etc/rsyslog.conf"
# 

directory=${1%/};
echo "Your selected Mountpoint Base-Directory is $directory"

mkdir -p $directory/config/{postfix,opendkim,rsyslog,supervisord}


#echo "[INFO] creating Configfiles from templates"
touch $directory/config/opendkim/SigningTable
touch $directory/config/postfix/main.cf
touch $directory/config/opendkim/KeyTable
touch $directory/config/supervisord/supervisord.conf
touch $directory/config/rsyslog/rsyslog.conf
touch $directory/config/postfix/header_checks
touch $directory/config/opendkim/opendkim.conf
touch $directory/config/opendkim/opendkim
touch $directory/config/opendkim/TrustedHosts