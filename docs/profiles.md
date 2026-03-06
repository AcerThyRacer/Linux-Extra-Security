# Profiles

Profiles are stored in `profiles/*.env`. They are declarative bundles that feed the same shell modules used by guided mode.

## Included Profiles

### `balanced-desktop`

- Good first profile for general desktop use
- Quad9 DoT
- usable Portmaster preset
- desktop-safe UFW posture

### `privacy-max`

- High-friction privacy-focused profile
- NextDNS local-forwarder
- strict Portmaster preset
- locked-down UFW posture

### `vpn-friendly`

- Built for systems that usually run behind a VPN
- NextDNS local-forwarder
- aggressive Portmaster preset with safer compatibility defaults
- vpn-friendly UFW posture

### `workstation-safe`

- Desktop plus developer workflow compromise
- AdGuard DoT
- balanced service posture
- browser and firewall defaults that are less disruptive

## Commands

Preview a profile:

```bash
./bin/linux-extra-security profile plan balanced-desktop
```

Apply a profile:

```bash
./bin/linux-extra-security profile apply balanced-desktop
```

## Creating a New Profile

Copy an existing `.env` file and adjust values like:

- `DNS_PROVIDER`
- `NEXTDNS_MODE`
- `PORTMASTER_PRESET`
- `UFW_PROFILE`
- `TELEMETRY_LEVEL`
- `SSH_HARDEN_MODE`
- `UPDATES_MODE`
- `APPARMOR_MODE`
- `FAIL2BAN_MODE`
- `SERVICES_PROFILE`
- `JOURNALD_PROFILE`
- `SYSCTL_PROFILE`
- `BROWSER_PROFILE`

Keep profiles free of machine-specific values and secrets.
