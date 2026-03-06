# Reporting

V2 adds both human-readable and machine-readable reporting.

## Verification Reports

Run:

```bash
./bin/linux-extra-security verify all
```

This writes reports into `.runtime/reports/`:

- `verification-*.txt`
- `verification-*.json`

## Audit Output

Run:

```bash
./bin/linux-extra-security audit
```

The audit view shows:

- detected OS
- DNS stack
- firewall state
- AppArmor and fail2ban status
- posture score
- basic network path details

## JSON Consumers

For automation pipelines:

```bash
./bin/linux-extra-security verify json
```

The JSON output includes a minimal check summary and verification score.
