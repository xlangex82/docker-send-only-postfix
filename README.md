# docker-send-only-postfix v2

Minimal **outbound-only SMTP relay** using Postfix and OpenDKIM. Accepts SMTP messages **only from explicitly trusted IP ranges**, signs outgoing mail for one configured domain and delivers via MX or optional smarthost. **No mailboxes, no IMAP/POP3, no inbound domain hosting.**

> Development rewrite on branch `v2-rewrite`. Test before deployment. Not a general-purpose mailserver.

## Quick start

```sh
git clone https://github.com/xlangex82/docker-send-only-postfix.git
cd docker-send-only-postfix
git checkout v2-rewrite
cp .env.example .env
# Edit DOMAIN, HOSTNAME_FQDN, MYNETWORKS
docker compose up -d --build
docker compose logs -f relay
```

The example binds **127.0.0.1:2525** on the Docker host, not a public interface. To accept clients on a private interface, adjust `ports` in `compose.yaml` **and** explicitly allow their actual source CIDRs in `MYNETWORKS`. Docker NAT/bridge addresses may differ from client addresses; inspect logs and test authorization. Never publish an unrestricted relay to the Internet.

## Configuration

| Variable | Meaning |
| --- | --- |
| `DOMAIN` | Signing domain (required) |
| `HOSTNAME_FQDN` | SMTP hostname (required) |
| `DKIM_SELECTOR` | DKIM selector; default `mail` |
| `MYNETWORKS` | Space/comma separated allowed CIDRs; default loopback only |
| `RELAYHOST` | Optional Postfix smarthost; empty = direct MX |
| `SMTP_TLS_SECURITY_LEVEL` | Outbound TLS policy; default `may` |

On **every start**, the entrypoint regenerates Postfix and OpenDKIM configuration from environment plus constrained overrides. Changes take effect after `docker compose up -d` / recreation. It does not dump environment variables to logs.

### DKIM DNS

Keys are generated on first start and stored in the persistent `dkim_keys` volume. Publish the TXT record from:

```sh
docker compose exec relay cat /var/lib/opendkim/keys/mail.txt
```

Replace `mail` with your selector. Keep the private key secret; back up the volume. Changing the signing domain requires a new selector/key volume to avoid accidental reuse.

### Optional overrides

Create `overrides/postfix/custom.conf` with allowed `main.cf` parameters:

```ini
message_size_limit = 52428800
smtp_destination_concurrency_limit = 10
```

Only a small allowlist of operational parameters is supported. Unsupported directives cause startup to **fail**. In particular, `S|`, `F|` and `P|` master.cf overrides are **intentionally blocked**, since service overrides could turn the relay into a receiving/delivery server. This is intentionally narrower than mailserver2/mailserver customization.

Optional `overrides/opendkim/custom.conf` supports selected directives such as:

```text
Canonicalization relaxed/relaxed
LogWhy yes
```

No full config-file replacement is supported; trust, signing tables and sockets are protected.

## Safety model

- Explicit SMTP client IP allowlist; all other SMTP clients rejected.
- `mydestination`, `relay_domains` and virtual domains are empty.
- Local and virtual delivery transports are disabled.
- `master.cf` is generated as a fixed service list without local/virtual delivery agents.
- Unsupported Postfix/OpenDKIM overrides fail closed.
- No mailbox server components installed.
- Queue and DKIM keys persist; Postfix/OpenDKIM configs do not.

**Threat boundary:** A user with Docker administrator access or the ability to replace container files/image can bypass these constraints. This image protects its documented configuration interface, not against a hostile Docker administrator. The relay still receives messages from authorized SMTP clients; that is required for sending.

**Before production:** Verify authorization, DKIM DNS, SPF/DMARC, reverse DNS, outbound port 25 availability, TLS policy and external deliverability. Direct-to-MX with mandatory TLS (`encrypt`) may fail for destinations without STARTTLS.

## Validation

```sh
docker compose config
docker compose run --rm relay check
docker compose up -d --build
docker compose ps
```

See `tests/test_config.py` for static security-contract checks.

## License

See [LICENSE](LICENSE). Originally forked from [davidepedranz/docker-send-only-postfix](https://github.com/davidepedranz/docker-send-only-postfix).
