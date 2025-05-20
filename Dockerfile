## #################################################################
## XlangeX82
## Description: Dockerfile for Postfix container as send only (relay) server
## Author:      Peter Lange
## Version:     2025-05-20

FROM ubuntu:24.04
LABEL maintainer="XlangeX82" \
      Description="XlangeX82 - Postfix send only container"

# install packages
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y --no-install-recommends supervisor postfix opendkim opendkim-tools rsyslog && \
    rm -rf /var/lib/apt/lists/* 

# mail server will be listening on this port
EXPOSE 25

# add configuration files
ADD ./config/supervisord/supervisord.conf   /template/etc/supervisor/supervisord.conf.tpl
ADD ./config/rsyslog/rsyslog.conf           /template/etc/rsyslog.conf.tpl
ADD ./config/postfix/main.cf                /template/etc/postfix/main.cf.tpl
ADD ./config/postfix/header_checks          /template/etc/postfix/header_checks.tpl
ADD ./config/opendkim/opendkim.conf         /template/etc/opendkim.conf.tpl
ADD ./config/opendkim/opendkim              /template/etc/default/opendkim.tpl
ADD ./config/opendkim/TrustedHosts          /template/etc/opendkim/TrustedHosts.tpl
ADD ./config/opendkim/SigningTable          /template/etc/opendkim/SigningTable.tpl
ADD ./config/opendkim/KeyTable              /template/etc/opendkim/KeyTable.tpl

# create empty config files
RUN touch /etc/supervisor/supervisord.conf
RUN echo "" > /etc/supervisor/supervisord.conf
RUN touch /etc/rsyslog.conf
RUN echo "" > /etc/rsyslog.conf
RUN echo "" > /etc/postfix/main.cf
RUN echo "" > /etc/postfix/header_checks
RUN echo "" > /etc/opendkim.conf
RUN echo "" > /etc/default/opendkim
RUN mkdir /etc/opendkim
RUN touch /etc/opendkim/TrustedHosts
RUN touch /etc/opendkim/SigningTable
RUN touch /etc/opendkim/KeyTable

# add initial setup script
ADD ./initial_setup.sh /initial_setup.sh
RUN chmod +x /initial_setup.sh
# configure the entrypoint
ADD ./docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]
