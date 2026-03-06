# Guided Flows

The default launcher now opens a guided menu so beginners can pick an outcome instead of memorizing module commands.

## Workflows

### `privacy-baseline`

- Profile: `balanced-desktop`
- DNS: Quad9 DoT
- Portmaster: usable
- UFW: desktop-safe

### `desktop-hardening`

- Profile: `workstation-safe`
- Safer for developer machines and daily desktop use
- Keeps a more conservative service and browser posture

### `vpn-friendly-lockdown`

- Profile: `vpn-friendly`
- Uses NextDNS local-forwarder mode
- Starts Portmaster in a VPN-friendlier compatibility posture

### `maximum-privacy`

- Profile: `privacy-max`
- Highest friction option in the repo
- Tightest UFW and host-hardening defaults

### `rollback`

- Opens the rollback selector
- Shows a preview before restoring files

## Example

```bash
./bin/linux-extra-security guided maximum-privacy
```

## Automation

Use `--yes` to auto-confirm prompts and `--dry-run` to preview without changing the system:

```bash
./bin/linux-extra-security --dry-run --yes guided desktop-hardening
```
