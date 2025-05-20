#!/bin/bash
set -e

echo "

██╗  ██╗██╗      █████╗ ███╗   ██╗ ██████╗ ███████╗██╗  ██╗ █████╗ ██████╗ 
╚██╗██╔╝██║     ██╔══██╗████╗  ██║██╔════╝ ██╔════╝╚██╗██╔╝██╔══██╗╚════██╗
 ╚███╔╝ ██║     ███████║██╔██╗ ██║██║  ███╗█████╗   ╚███╔╝ ╚█████╔╝ █████╔╝
 ██╔██╗ ██║     ██╔══██║██║╚██╗██║██║   ██║██╔══╝   ██╔██╗ ██╔══██╗██╔═══╝ 
██╔╝ ██╗███████╗██║  ██║██║ ╚████║╚██████╔╝███████╗██╔╝ ██╗╚█████╔╝███████╗
╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝ ╚════╝ ╚══════╝
                                                                           
Send-Only-Postfix Relay Server - ENTRYPOINT
"
echo "[INFO] Setting up container"

echo "[ENV] Your ENVIRONMENT variables are:"
env

# read domain from environment
if [ -z "${DOMAIN}" ]; then
    echo "DOMAIN environment variable not found. Please set it before running this Docker container."
    exit 1
fi
# read HOSTNAME_FQDN from environment
if [ -z "${HOSTNAME_FQDN}" ]; then
    echo "HOSTNAME_FQDN environment variable not found. Please set it before running this Docker container."
    exit 1
fi
# read MYNETWORKS from environment
if [ -z "${MYNETWORKS}" ]; then
    echo "MYNETWORKS environment variable not found. Please set it before running this Docker container."
    exit 1
fi
# read DKIM_SELEKTOR from environment
if [ -z "${DKIM_SELEKTOR}" ]; then
    echo "DKIM_SELEKTOR environment variable not found. Please set it before running this Docker container."
    exit 1
fi

echo "[INFO] Finished environment check - starting services now"

# launch the processes supervisor
/usr/bin/supervisord -c /etc/supervisor/supervisord.conf
