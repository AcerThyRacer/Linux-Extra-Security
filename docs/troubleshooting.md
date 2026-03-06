# Troubleshooting

## Lost DNS After Changes

- Run `./bin/linux-extra-security dns status`
- Run `./bin/linux-extra-security rollback module dns`
- If using Portmaster with NextDNS, prefer the `local-forwarder` mode

## Portmaster Broke Local DNS

- Export the current config with `./bin/linux-extra-security portmaster export`
- Use a profile that keeps NextDNS on `127.0.0.1:<port>`
- Avoid forcing bypass prevention when a localhost encrypted DNS forwarder is involved

## UFW Broke Connectivity

- Review `./bin/linux-extra-security firewall status`
- Restore the last firewall manifest with `./bin/linux-extra-security rollback module ufw`
- Use `--dry-run` to preview a stricter profile before reapplying it

## Browser Still Bypasses DNS

- Check the verification output for browser hints
- Use `./bin/linux-extra-security browser apply privacy-baseline`
- Disable Secure DNS in Chromium-family browsers if they still use an internal provider

## Dry-Run First

Most risky changes can be previewed:

```bash
./bin/linux-extra-security --dry-run --yes profile apply privacy-max
```
