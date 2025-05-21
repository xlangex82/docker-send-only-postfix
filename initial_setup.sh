#!/bin/bash
set -e

echo "

██╗  ██╗██╗      █████╗ ███╗   ██╗ ██████╗ ███████╗██╗  ██╗ █████╗ ██████╗ 
╚██╗██╔╝██║     ██╔══██╗████╗  ██║██╔════╝ ██╔════╝╚██╗██╔╝██╔══██╗╚════██╗
 ╚███╔╝ ██║     ███████║██╔██╗ ██║██║  ███╗█████╗   ╚███╔╝ ╚█████╔╝ █████╔╝
 ██╔██╗ ██║     ██╔══██║██║╚██╗██║██║   ██║██╔══╝   ██╔██╗ ██╔══██╗██╔═══╝ 
██╔╝ ██╗███████╗██║  ██║██║ ╚████║╚██████╔╝███████╗██╔╝ ██╗╚█████╔╝███████╗
╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝ ╚════╝ ╚══════╝
                                                                           
Send-Only-Postfix Relay Server - INITIAL SETUP
"
echo "[Initail Setup] Setting up container"

echo "[ENV] Your ENVIRONMENT variables are:"
env
echo "[INFO] replacing values in config file templates"
# replace the placeholders in the configuration files
PATTERN="s/\${DOMAIN}/$DOMAIN/g"
sed -i "${PATTERN}" /template/etc/opendkim/SigningTable.tpl
sed -i "${PATTERN}" /template/etc/postfix/main.cf.tpl
sed -i "${PATTERN}" /template/etc/opendkim/KeyTable.tpl

PATTERN="s/\${HOSTNAME_FQDN}/$HOSTNAME_FQDN/g"
sed -i "${PATTERN}" /template/etc/postfix/main.cf.tpl
#PATTERN="s/\${MYNETWORKS}/$MYNETWORKS/g"
#sed -i "${PATTERN}" /template/etc/postfix/main.cf.tpl
PATTERN="s/\${MYDESTINATION}/$MYDESTINATION/g"
sed -i "${PATTERN}" /template/etc/postfix/main.cf.tpl

PATTERN="s/\${DKIM_SELEKTOR}/$DKIM_SELEKTOR/g"
sed -i "${PATTERN}" /template/etc/opendkim/SigningTable.tpl
sed -i "${PATTERN}" /template/etc/opendkim/KeyTable.tpl


echo "[INFO] creating Configfiles from templates"
cat /template/etc/opendkim/SigningTable.tpl > /etc/opendkim/SigningTable
cat /template/etc/postfix/main.cf.tpl > /etc/postfix/main.cf
cat /template/etc/opendkim/KeyTable.tpl > /etc/opendkim/KeyTable

cp /template/etc/supervisor/supervisord.conf.tpl /etc/supervisor/supervisord.conf
cp /template/etc/rsyslog.conf.tpl /etc/rsyslog.conf
cp /template/etc/postfix/header_checks.tpl /etc/postfix/header_checks
cp /template/etc/opendkim.conf.tpl /etc/opendkim.conf
cp /template/etc/default/opendkim.tpl /etc/default/opendkim
cp /template/etc/opendkim/TrustedHosts.tpl /etc/opendkim/TrustedHosts


echo "[INFO] Check for DKIM keys"
# check the presence of the key for opendkim
if [ ! -f /etc/opendkim/domainkeys/${DKIM_SELEKTOR}.private ]; then
    echo "[INFO] DKIM Keys doesn't exist in '/etc/opendkim/domainkeys/' for Selektor ${DKIM_SELEKTOR}."
    echo "[INFO] Trying to generate a DKIM Key for selektor ${DKIM_SELEKTOR}"
    mkdir -p /etc/opendkim/domainkeys
    opendkim-genkey -s ${DKIM_SELEKTOR} -d ${DOMAIN} --directory=/etc/opendkim/domainkeys/ && echo "[INFO] DKIM key generated"
fi


# fix permissions on files
echo "[INFO] check and fix permission on DKIM key file(s)"
chown opendkim:opendkim /etc/opendkim/domainkeys
chown opendkim:opendkim /etc/opendkim/domainkeys/${DKIM_SELEKTOR}.private
chmod 400 /etc/opendkim/domainkeys/${DKIM_SELEKTOR}.private


echo "[INFO] Finished container setup"


echo "[SUCCESS] Initial setup is done - check local volume - start with docker compose up -d"
