FROM debian:bookworm-slim
LABEL org.opencontainers.image.source="https://github.com/xlangex82/docker-send-only-postfix"
ENV DEBIAN_FRONTEND=noninteractive
RUN echo "postfix postfix/mailname string localhost" | debconf-set-selections && \
    echo "postfix postfix/main_mailer_type string Internet Site" | debconf-set-selections && \
    apt-get update && apt-get install -y --no-install-recommends postfix opendkim opendkim-tools python3 ca-certificates && \
    rm -rf /var/lib/apt/lists/*
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
COPY scripts/configure.py /usr/local/bin/configure-relay
RUN chmod 755 /usr/local/bin/docker-entrypoint.sh /usr/local/bin/configure-relay && mkdir -p /overrides /var/lib/opendkim/keys
EXPOSE 25
VOLUME ["/var/lib/opendkim/keys", "/var/spool/postfix"]
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
