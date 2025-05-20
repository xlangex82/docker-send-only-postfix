#!/usr/bin/env sh
set -e

echo "

██╗  ██╗██╗      █████╗ ███╗   ██╗ ██████╗ ███████╗██╗  ██╗ █████╗ ██████╗ 
╚██╗██╔╝██║     ██╔══██╗████╗  ██║██╔════╝ ██╔════╝╚██╗██╔╝██╔══██╗╚════██╗
 ╚███╔╝ ██║     ███████║██╔██╗ ██║██║  ███╗█████╗   ╚███╔╝ ╚█████╔╝ █████╔╝
 ██╔██╗ ██║     ██╔══██║██║╚██╗██║██║   ██║██╔══╝   ██╔██╗ ██╔══██╗██╔═══╝ 
██╔╝ ██╗███████╗██║  ██║██║ ╚████║╚██████╔╝███████╗██╔╝ ██╗╚█████╔╝███████╗
╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝ ╚════╝ ╚══════╝
                                                                           
Send-Only-Postfix Relay Server
"

DOMAIN=${DOMAIN:-}
HOSTNAME_FQDN=${HOSTNAME_FQDN:-}
MYNETWORKS=${MYNETWORKS:-}
MYDESTINATION=${MYDESTINATION:-}
DKIM_SELEKTOR=${DKIM_SELEKTOR:-}



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

# TODO: escape domain!

# replace the placeholders in the configuration files
PATTERN="s/\${DOMAIN}/${DOMAIN}/g"
sed -i ${PATTERN} /etc/postfix/main.cf
sed -i ${PATTERN} /etc/opendkim/SigningTable
sed -i ${PATTERN} /etc/opendkim/KeyTable

PATTERN="s/\${HOSTNAME_FQDN}/${HOSTNAME_FQDN}/g"
sed -i ${PATTERN} /etc/postfix/main.cf
PATTERN="s/\${MYNETWORKS}/${MYNETWORKS}/g"
sed -i ${PATTERN} /etc/postfix/main.cf
PATTERN="s/\${MYDESTINATION}/${MYDESTINATION}/g"
sed -i ${PATTERN} /etc/postfix/main.cf

PATTERN="s/\${DKIM_SELEKTOR}/${DKIM_SELEKTOR}/g"
sed -i ${PATTERN} /etc/opendkim/SigningTable
sed -i ${PATTERN} /etc/opendkim/KeyTable

# check the presence of the key for opendkim
if [ ! -f /etc/opendkim/domainkeys/${DKIM_SELEKTOR}.private ]; then
    echo "DKIM Keys doesn't exist in '/etc/opendkim/domainkeys/' for Selektor ${DKIM_SELEKTOR}."
    echo " Trying to generate a DKIM Key for selektor ${DKIM_SELEKTOR}"
    opendkim-genkey -s ${DKIM_SELEKTOR} -d ${DOMAIN} --directory=/etc/opendkim/domainkeys/
fi

# fix permissions on files
chown opendkim:opendkim /etc/opendkim/domainkeys
chown opendkim:opendkim /etc/opendkim/domainkeys/${DKIM_SELEKTOR}.private
chmod 400 /etc/opendkim/domainkeys/${DKIM_SELEKTOR}.private

# launch the processes supervisor
/usr/bin/supervisord -c /etc/supervisor/supervisord.conf
