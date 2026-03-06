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
- `/etc/default/apport`
- `/etc/default/popularity-contest`
- `/etc/ssh/sshd_config.d/99-linux-extra-security.conf`
- `/etc/apt/apt.conf.d/20auto-upgrades`
- `/etc/fail2ban/jail.d/99-linux-extra-security.conf`
- `/etc/systemd/journald.conf.d/99-linux-extra-security.conf`
- `/etc/sysctl.d/99-linux-extra-security.conf`
- `/etc/firefox/policies/policies.json`

## Show Rollback Points

```bash
./bin/linux-extra-security rollback list
```

## Restore Interactively

```bash
./bin/linux-extra-security rollback interactive
```

The guided rollback flow shows a preview before restoring files.

## Restore a Specific Module

```bash
./bin/linux-extra-security rollback module dns
./bin/linux-extra-security rollback module ufw
./bin/linux-extra-security rollback module portmaster
```

## Dry-Run Preview

```bash
./bin/linux-extra-security --dry-run rollback module dns
```

## Manual Recovery Tips

If you need to recover manually:

- stop and deactivate `nextdns` if a DNS change broke connectivity
- remove the toolkit `systemd-resolved` drop-in and restart `systemd-resolved`
- restore `/var/lib/portmaster/config.json` from a backup copy and restart `portmaster`
- restore `/etc/ufw` from a backup copy and reload or re-enable `ufw`

## Public Repo Safety

Never copy the contents of `.runtime/` into git. That data is machine-local and may contain host-specific paths or settings.
