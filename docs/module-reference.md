# Module Reference

## Core Commands

- `dns`
- `portmaster`
- `firewall`
- `telemetry`
- `ssh`
- `updates`
- `apparmor`
- `fail2ban`
- `services`
- `journald`
- `sysctl`
- `browser`
- `audit`
- `verify`
- `rollback`

## Typical Actions

### Status

```bash
./bin/linux-extra-security dns status
./bin/linux-extra-security firewall status
./bin/linux-extra-security show-status
```

### Plan

```bash
./bin/linux-extra-security firewall plan locked-down
./bin/linux-extra-security profile plan privacy-max
```

### Apply

```bash
./bin/linux-extra-security ssh apply safe
./bin/linux-extra-security journald apply private
./bin/linux-extra-security sysctl apply hardened
```

### Reporting

```bash
./bin/linux-extra-security audit
./bin/linux-extra-security verify all
./bin/linux-extra-security verify json
```

### Recovery

```bash
./bin/linux-extra-security rollback list
./bin/linux-extra-security rollback module ufw
```
