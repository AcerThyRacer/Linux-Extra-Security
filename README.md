# Linux Extra Security

Interactive shell toolkit for Debian, Ubuntu, and Zorin systems that helps configure:

- privacy DNS with provider selection
- Portmaster privacy presets
- UFW outbound lockdown profiles
- verification checks and rollback manifests

The project is designed for public use. It does **not** ship real profile IDs, local IPs, hostnames, or machine backups.

## Features

- Interactive entrypoint: `bin/linux-extra-security`
- Multi-provider DNS workflow:
  - NextDNS via `nextdns` CLI
  - Quad9, AdGuard, and Cloudflare via `systemd-resolved` DNS-over-TLS
  - custom `systemd-resolved` values
- Portmaster presets with compatibility logic for localhost DNS forwarders
- Staged UFW profiles:
  - `balanced`
  - `vpn-friendly`
  - `strict`
- Runtime backups and rollback manifests stored in `.runtime/`
- Smoke tests that check shell syntax and secret scrubbing

## Quick Start

```bash
git clone https://github.com/AcerThyRacer/Linux-Extra-Security.git
cd Linux-Extra-Security
chmod +x bin/linux-extra-security tests/smoke-test.sh
./bin/linux-extra-security
```

If you want a direct action:

```bash
./bin/linux-extra-security configure-dns
./bin/linux-extra-security configure-portmaster
./bin/linux-extra-security configure-ufw
./bin/linux-extra-security verify
```

## Supported Distros

- Debian
- Ubuntu
- Zorin OS

The toolkit assumes `systemd-resolved` and `apt` are available for the DNS and package management flows.

## Safety Model

- Every destructive step asks for confirmation.
- Backups are recorded before writing `NextDNS`, `Portmaster`, or `UFW` state.
- `UFW` profiles are deny-by-default, so read the prompts carefully.
- Direct domain blocking belongs at the DNS layer, not in `UFW`.

## Runtime State

Generated backups and manifests go to:

```text
.runtime/
```

That folder is gitignored and intended for local-only state.

## Provider Notes

- `NextDNS`: prompts for your profile ID at runtime and never stores it in git.
- `Quad9`, `AdGuard`, `Cloudflare`: configured through `systemd-resolved` using DNS-over-TLS.
- `Portmaster`: if a localhost `NextDNS` listener is detected, the toolkit automatically prefers a compatible mode instead of forcing bypass prevention.

## Verification

Run:

```bash
./bin/linux-extra-security verify
./tests/smoke-test.sh
```

The verification flow checks:

- web reachability
- direct DNS bypass attempts
- NextDNS status when configured
- malware test resolution
- backup presence

## Docs

- [`docs/architecture.md`](docs/architecture.md)
- [`docs/providers.md`](docs/providers.md)
- [`docs/rollback.md`](docs/rollback.md)

## License

Apache-2.0. See [`LICENSE`](LICENSE).
