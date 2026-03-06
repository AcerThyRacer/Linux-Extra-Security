# Rollback

## Where Backups Go

Local backups are written under:

```text
.runtime/backups/
.runtime/state/
```

These folders are gitignored and are meant to stay local to the machine where the toolkit runs.

## What Gets Backed Up

Depending on the module you use, the toolkit may capture:

- `/etc/nextdns.conf`
- `/etc/systemd/resolved.conf.d/99-linux-extra-security.conf`
- `/var/lib/portmaster/config.json`
- `/etc/ufw`

## Restore the Latest Manifest

```bash
./bin/linux-extra-security rollback
```

The rollback flow restores the files recorded in the latest manifest. At the moment the built-in interactive rollback is focused on the most recent UFW manifest, because firewall mistakes are the most likely to break connectivity.

## Manual Recovery Tips

If you need to recover manually:

- stop and deactivate `nextdns` if a DNS change broke connectivity
- remove the toolkit `systemd-resolved` drop-in and restart `systemd-resolved`
- restore `/var/lib/portmaster/config.json` from a backup copy and restart `portmaster`
- restore `/etc/ufw` from a backup copy and reload or re-enable `ufw`

## Public Repo Safety

Never copy the contents of `.runtime/` into git. That data is machine-local and may contain host-specific paths or settings.
