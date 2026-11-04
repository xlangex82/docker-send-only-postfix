#!/bin/sh
set -eu
/usr/local/bin/configure-relay
if [ "${1:-}" = "check" ]; then
  postfix check
  opendkim -n -x /etc/opendkim.conf
  exit 0
fi
if [ "$#" -gt 0 ]; then exec "$@"; fi
postfix check
opendkim -n -x /etc/opendkim.conf
mkdir -p /var/run/opendkim
chown opendkim:opendkim /var/run/opendkim
opendkim -x /etc/opendkim.conf -f &
dkim_pid=$!
cleanup() { postfix stop || true; kill "$dkim_pid" 2>/dev/null || true; wait "$dkim_pid" 2>/dev/null || true; }
trap cleanup TERM INT
postfix start
echo "Send-only relay started"
while kill -0 "$dkim_pid" 2>/dev/null && postfix status >/dev/null 2>&1; do sleep 2 & wait $! || true; done
echo "A required service stopped" >&2
cleanup
exit 1
