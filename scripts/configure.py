#!/usr/bin/env python3
"""Generate a deliberately constrained, send-only Postfix/OpenDKIM configuration."""
import ipaddress
import os
import pathlib
import re
import subprocess
import sys

def fail(message):
    sys.exit("Configuration error: " + message)

def env(name, default=""):
    return os.environ.get(name, default).strip()

def domain(value, name):
    if not re.fullmatch(r"(?=.{1,253}$)[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?)+", value):
        fail(name + " must be a valid DNS domain/FQDN")
    return value.lower()

def run(*args):
    subprocess.run(args, check=True)

def write(path, content, mode=0o644):
    p = pathlib.Path(path)
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(content)
    p.chmod(mode)

domain_name = domain(env("DOMAIN"), "DOMAIN")
hostname = domain(env("HOSTNAME_FQDN"), "HOSTNAME_FQDN")
selector = env("DKIM_SELECTOR", env("DKIM_SELEKTOR", "mail"))
if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9_-]{0,62}", selector):
    fail("DKIM_SELECTOR must be a simple DNS label")
networks = env("MYNETWORKS", "127.0.0.0/8 [::1]/128").replace(",", " ").split()
if not networks:
    fail("MYNETWORKS must not be empty")
for network in networks:
    try:
        ipaddress.ip_network(network.strip("[]"), strict=False)
    except ValueError:
        fail("invalid MYNETWORKS entry: " + network)
    if network in ("0.0.0.0/0", "::/0", "[::]/0"):
        fail("MYNETWORKS must not trust the entire Internet")
relayhost = env("RELAYHOST")
if relayhost and not re.fullmatch(r"(?:\[[A-Za-z0-9.:-]+\]|[A-Za-z0-9.-]+)(?::[0-9]{1,5})?", relayhost):
    fail("invalid RELAYHOST")
tls = env("SMTP_TLS_SECURITY_LEVEL", "may")
if tls not in ("may", "encrypt", "verify", "secure", "dane", "dane-only"):
    fail("invalid SMTP_TLS_SECURITY_LEVEL")

# Only these keys are accepted from custom.conf. Unknown settings fail closed.
allowed = {
    "message_size_limit", "smtp_destination_concurrency_limit",
    "default_destination_concurrency_limit", "smtp_destination_rate_delay",
    "smtp_connect_timeout", "smtp_helo_timeout", "smtp_mail_timeout",
    "smtp_rcpt_timeout", "smtp_data_xfer_timeout", "smtp_tls_loglevel",
    "smtp_tls_CAfile", "smtp_tls_CApath", "smtp_tls_protocols",
    "smtp_tls_mandatory_protocols", "smtpd_client_connection_count_limit",
    "smtpd_client_connection_rate_limit", "smtpd_client_message_rate_limit",
    "smtpd_timeout", "smtpd_banner", "maximal_queue_lifetime",
    "bounce_queue_lifetime", "delay_warning_time",
}
settings = {
    "myhostname": hostname,
    "mydomain": domain_name,
    "myorigin": domain_name,
    "mydestination": "",
    "relay_domains": "",
    "virtual_mailbox_domains": "",
    "virtual_alias_domains": "",
    "local_transport": "error:Local delivery disabled",
    "virtual_transport": "error:Virtual delivery disabled",
    "mailbox_transport": "error:Mailbox delivery disabled",
    "inet_interfaces": "all",
    "inet_protocols": "ipv4",
    "mynetworks_style": "host",
    "mynetworks": " ".join(networks),
    "relayhost": relayhost,
    "smtpd_relay_restrictions": "permit_mynetworks,reject",
    "smtpd_recipient_restrictions": "permit_mynetworks,reject",
    "smtpd_client_restrictions": "permit_mynetworks,reject",
    "smtpd_sender_restrictions": "",
    "smtpd_tls_security_level": "none",
    "smtp_tls_security_level": tls,
    "smtpd_milters": "inet:127.0.0.1:12301",
    "non_smtpd_milters": "inet:127.0.0.1:12301",
    "milter_default_action": "tempfail",
    "milter_protocol": "6",
    "biff": "no",
    "append_dot_mydomain": "no",
    "compatibility_level": "3.6",
}
custom = pathlib.Path("/overrides/postfix/custom.conf")
if custom.exists():
    for lineno, raw in enumerate(custom.read_text().splitlines(), 1):
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        if line.startswith(("S|", "F|", "P|")):
            fail(f"custom.conf:{lineno}: master.cf overrides are deliberately unsupported (send-only protection)")
        if "=" not in line:
            fail(f"custom.conf:{lineno}: expected key = value")
        key, value = (part.strip() for part in line.split("=", 1))
        if key not in allowed or "\n" in value or "\r" in value:
            fail(f"custom.conf:{lineno}: parameter not allowed: {key}")
        settings[key] = value

# Regenerate on EVERY start; never persist editable main.cf.
write("/etc/postfix/main.cf", "".join(f"{key} = {value}\n" for key, value in settings.items()))
# Replace master.cf with an explicit minimal service set, no local or virtual delivery.
write("/etc/postfix/master.cf", """smtp inet n - n - - smtpd
pickup unix n - n 60 1 pickup
cleanup unix n - n - 0 cleanup
qmgr unix n - n 300 1 qmgr
tlsmgr unix - - n 1000? 1 tlsmgr
rewrite unix - - n - - trivial-rewrite
bounce unix - - n - 0 bounce
defer unix - - n - 0 bounce
trace unix - - n - 0 bounce
verify unix - - n - 1 verify
flush unix n - n 1000? 0 flush
smtp unix - - n - - smtp
relay unix - - n - - smtp
showq unix n - n - - showq
error unix - - n - - error
retry unix - - n - - error
discard unix - - n - - discard
""")
keys = pathlib.Path("/var/lib/opendkim/keys")
keys.mkdir(parents=True, exist_ok=True)
private = keys / f"{selector}.private"
public = keys / f"{selector}.txt"
if not private.exists():
    # Existing selector keys are intentionally never overwritten.
    if public.exists():
        fail("DKIM public record exists without private key")
    run("opendkim-genkey", "-b", "2048", "-s", selector, "-d", domain_name, "-D", str(keys))
# Avoid selector reuse with a different DOMAIN.
marker = keys / f"{selector}.domain"
if marker.exists() and marker.read_text().strip() != domain_name:
    fail("DKIM selector already belongs to another DOMAIN")
marker.write_text(domain_name + "\n")
run("chown", "opendkim:opendkim", str(private))
private.chmod(0o600)
write("/etc/opendkim/KeyTable", f"{selector}._domainkey.{domain_name} {domain_name}:{selector}:{private}\n")
write("/etc/opendkim/SigningTable", f"*@{domain_name} {selector}._domainkey.{domain_name}\n")
# OpenDKIM only signs mail from the trusted SMTP clients.
write("/etc/opendkim/TrustedHosts", "\n".join(["127.0.0.1", "::1"] + [n.strip("[]") for n in networks]) + "\n")
opendkim_options = {
    "Syslog": "yes",
    "UMask": "007",
    "Mode": "s",
    "Canonicalization": "relaxed/simple",
    "Socket": "inet:12301@127.0.0.1",
    "UserID": "opendkim:opendkim",
    "InternalHosts": "refile:/etc/opendkim/TrustedHosts",
    "ExternalIgnoreList": "refile:/etc/opendkim/TrustedHosts",
    "KeyTable": "refile:/etc/opendkim/KeyTable",
    "SigningTable": "refile:/etc/opendkim/SigningTable",
}
# Limited OpenDKIM customizations; signing trust/key ownership cannot be replaced.
dkim_allowed = {"Canonicalization", "SignatureAlgorithm", "OversignHeaders", "SignHeaders", "SyslogSuccess", "LogWhy"}
dkim_custom = pathlib.Path("/overrides/opendkim/custom.conf")
if dkim_custom.exists():
    for lineno, raw in enumerate(dkim_custom.read_text().splitlines(), 1):
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        parts = line.split(None, 1)
        if len(parts) != 2 or parts[0] not in dkim_allowed:
            fail(f"opendkim/custom.conf:{lineno}: directive not allowed")
        opendkim_options[parts[0]] = parts[1]
write("/etc/opendkim.conf", "".join(f"{k} {v}\n" for k, v in opendkim_options.items()))
print(f"Configured send-only relay for {hostname}; DKIM selector {selector}; {len(networks)} trusted network(s)")
