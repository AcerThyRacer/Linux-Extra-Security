# Linux Extra Security

`Linux Extra Security` is a shell-only privacy and hardening toolkit for Debian-family systems. V2 adds a guided launcher for beginners, reusable profiles for repeatable setups, broader host hardening, richer verification, and stronger rollback/reporting.

The repository is public-safe by design. It does **not** ship real NextDNS profile IDs, local hostnames, private IPs, or runtime backups.

## What V2 Adds

- Guided workflows:
  - `privacy-baseline`
  - `desktop-hardening`
  - `vpn-friendly-lockdown`
  - `maximum-privacy`
- Reusable profiles:
  - `balanced-desktop`
  - `privacy-max`
  - `vpn-friendly`
  - `workstation-safe`
- Expanded modules:
  - DNS
  - Portmaster
  - UFW firewalling
  - telemetry reduction
  - SSH hardening
  - unattended updates
  - AppArmor
  - fail2ban
  - service pruning
  - journald privacy controls
  - sysctl hardening
  - browser resolver alignment
- Reporting:
  - human-readable verification output
  - JSON verification reports
  - posture audit output
  - network path reporting
- Recovery:
  - per-module rollback manifests
  - rollback listing and preview
  - targeted rollback by module

## Quick Start

```bash
git clone https://github.com/AcerThyRacer/Linux-Extra-Security.git
cd Linux-Extra-Security
chmod +x bin/linux-extra-security tests/*.sh
./bin/linux-extra-security
```

Default launch opens the guided flow. For a repeatable non-interactive-ish path, preview a profile first:

```bash
./bin/linux-extra-security profile plan balanced-desktop
./bin/linux-extra-security profile apply balanced-desktop
```

## Common Commands

```bash
./bin/linux-extra-security guided maximum-privacy
./bin/linux-extra-security dns status
./bin/linux-extra-security firewall plan locked-down
./bin/linux-extra-security verify all
./bin/linux-extra-security rollback list
./bin/linux-extra-security --dry-run --yes profile apply workstation-safe
```

## Package Groups

```bash
./bin/linux-extra-security install-tools base
./bin/linux-extra-security install-tools host-hardening
./bin/linux-extra-security install-tools all
```

## Supported Systems

- Debian
- Ubuntu
- Zorin OS

Assumptions:

- `apt` is the package manager
- `systemd` is present
- `systemd-resolved` is available for DoT-based DNS flows
- `Portmaster` is optional, but supported when installed

## Safety Model

- Every apply flow shows a plan first.
- Machine changes are recorded into `.runtime/state/*.manifest`.
- Backups are copied into `.runtime/backups/` before file writes.
- `--dry-run` prints intended commands without changing the machine.
- `--yes` auto-confirms prompts for automation.
- DNS/domain-scale blocking stays at the resolver and Portmaster layers rather than trying to force that into `UFW`.

## Runtime Data

All local state stays in the gitignored `.runtime/` directory:

```text
.runtime/
  backups/
  reports/
  state/
```

## Documentation

- [`docs/architecture.md`](docs/architecture.md)
- [`docs/guided-flows.md`](docs/guided-flows.md)
- [`docs/profiles.md`](docs/profiles.md)
- [`docs/debian-compatibility.md`](docs/debian-compatibility.md)
- [`docs/module-reference.md`](docs/module-reference.md)
- [`docs/providers.md`](docs/providers.md)
- [`docs/reporting.md`](docs/reporting.md)
- [`docs/rollback.md`](docs/rollback.md)
- [`docs/troubleshooting.md`](docs/troubleshooting.md)
- [`docs/examples/`](docs/examples)

## Verification

```bash
./bin/linux-extra-security verify all
./tests/smoke-test.sh
./tests/profile-test.sh
./tests/dry-run-test.sh
```

## License

Apache-2.0. See [`LICENSE`](LICENSE).
