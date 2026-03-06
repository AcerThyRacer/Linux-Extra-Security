# Debian Compatibility

The toolkit targets Debian-family systems and is tested as a shell-only project.

## Intended Targets

- Debian
- Ubuntu
- Zorin OS

## Assumptions

- `apt` is available
- `systemd` is available
- `systemd-resolved` exists for DoT-based resolver flows
- `sudo` is available for privileged operations

## Optional Components

- `Portmaster` is optional
- `nextdns` CLI is optional and only required for NextDNS flows
- `AppArmor`, `fail2ban`, and `unattended-upgrades` can be installed by the toolkit

## Caveats

- Minimal server installs may not have `systemd-resolved` enabled by default.
- Browser policy paths vary more between Chromium-family packages than Firefox.
- `UFW` should not be layered blindly on top of a heavily customized `nftables` setup.
- Some desktop services disabled by privacy profiles may be useful on laptops or printer-heavy networks.
