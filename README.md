# Linux Extra Security

> **A super simple, interactive privacy and security tool for Linux.**
> Run a command, answer easy questions, and make your system safer. No expert skills needed!

---

## What does this do?

Out of the box, Linux systems sometimes send out data or have settings that aren't the most secure. This tool fixes that! It can:
- Encrypt your internet traffic (DNS) so your ISP can't see what websites you visit.
- Stop your computer from sending unnecessary data and crash reports to companies.
- Add a firewall to stop bad apps from connecting to the internet.
- Disable unused, risky features (like USB storage, Core Dumps, or leaving your MAC address the same).

### 🌟 New: Super Simple Interactive Menus and "Lite" Modes
You can now decide exactly what happens!
- **Interactive:** If you run a command like `./bin/linux-extra-security ssh apply`, it will ask you what you want to do. You are in control!
- **"Lite" Mode:** Almost every feature now has a **"lite"** mode. Lite mode makes small, extremely safe changes that use almost zero system resources. It gives you basic security without ever breaking your computer.

---

## Table of Contents

- [Requirements](#requirements)
- [Quick Start](#quick-start)
- [Interactive Menus](#interactive-menus)
- [Individual Modules](#individual-modules)
- [Safety and Undo](#safety-and-undo)

---

## Requirements

| Requirement | Notes |
|---|---|
| Debian, Ubuntu, or Zorin OS | Other `apt`-based distros may work |
| `sudo` access | Most changes need root |
| `bash` 4+ | Pre-installed on all supported systems |
| Internet connection | Required to install optional packages |

Optional but recommended:
- [Portmaster](https://safing.io/portmaster/) installed — enables app-level firewall features

---

## Quick Start

### Option A — Guided (recommended for beginners)

Just run the script with no arguments and it will walk you through everything:

```bash
git clone https://github.com/AcerThyRacer/Linux-Extra-Security.git
cd Linux-Extra-Security
chmod +x bin/linux-extra-security tests/*.sh
./bin/linux-extra-security
```

You will see a menu like this:

```
Linux Extra Security guided workflows
  1. privacy-baseline
  2. desktop-hardening
  3. vpn-friendly-lockdown
  4. maximum-privacy
  5. rollback
Select an option [1-5]:
```

Pick one and the toolkit guides you through each step, showing a **plan** before making any changes.

---

### Option B — Apply a preset profile directly

If you already know what you want, preview it first, then apply it:

```bash
# Step 1: See exactly what will change (nothing is modified yet)
./bin/linux-extra-security profile plan balanced-desktop

# Step 2: Apply it when you are happy with the plan
./bin/linux-extra-security profile apply balanced-desktop
```

---

## Interactive Menus

Whenever you run a command to apply a setting without telling it exactly what to do, it will give you choices.

For example:
```bash
./bin/linux-extra-security telemetry apply
```

Will show you:
```
Select Telemetry Reduction Level:
  1. lite
  2. balanced
  3. strict
Select an option [1-3]:
```
Just type a number and hit enter! The script will explain what it's about to do and ask for a final confirmation before changing anything.

---

## Guided Workflows

Guided workflows are the easiest way to do a bunch of things at once. Pick one:

### `privacy-baseline`
> **Best for:** Most desktop users who want meaningful privacy without breaking things

- DNS: Quad9 (encrypted, no account needed)
- Portmaster: usable preset (blocks ads, trackers, malware)
- UFW: desktop-safe outbound rules
- Telemetry: standard reduction
- AppArmor: enabled

```bash
./bin/linux-extra-security guided privacy-baseline
```

---

### `desktop-hardening`
> **Best for:** Developers and power users who need a secure but functional workstation

- DNS: AdGuard (encrypted DoT)
- Portmaster: usable preset
- UFW: balanced rules (preserves developer ports)
- Services: prunes unnecessary background services
- Browser: aligns Firefox/Chromium with system DNS

```bash
./bin/linux-extra-security guided desktop-hardening
```

---

### `vpn-friendly-lockdown`
> **Best for:** Users who already run a VPN and want an extra layer of privacy on top

- DNS: NextDNS in local-forwarder mode (prompts for your profile ID)
- Portmaster: aggressive preset, VPN-compatible
- UFW: VPN-friendly outbound rules (keeps VPN ports open)
- Journald: balanced privacy controls

```bash
./bin/linux-extra-security guided vpn-friendly-lockdown
```

---

### `maximum-privacy`
> **Best for:** Maximum blocking. Warning: This might break some internet things until you adjust it!

```bash
./bin/linux-extra-security guided maximum-privacy
```

---

## Individual Modules

You can apply security settings to just one part of your system. Below are some useful ones. Remember, running `apply` with no extra text will show an interactive menu!

### 🔌 **NEW:** USB Storage Restriction
Stops random USB drives from reading/writing files on your computer.
```bash
./bin/linux-extra-security usb apply
# Options: 'lite' (logs it), 'strict' (blocks it totally)
```

### 📡 **NEW:** MAC Address Randomization
Changes your Wi-Fi hardware address to stop networks from tracking you.
```bash
./bin/linux-extra-security mac apply
# Options: 'lite' (changes per network), 'strict' (changes every time)
```

### 🛑 **NEW:** Core Dump Restriction
Stops Linux from saving its memory to your hard drive when a program crashes (which can leak passwords).
```bash
./bin/linux-extra-security coredump apply
# Options: 'lite' (restricts access), 'strict' (turns off entirely)
```

### Telemetry (Stop sending data)
```bash
./bin/linux-extra-security telemetry apply
```

### SSH (Secure remote logins)
```bash
./bin/linux-extra-security ssh apply
```

### AppArmor (Isolate apps)
```bash
./bin/linux-extra-security apparmor apply
```

---

## Safety and Undo

**Backups are automatic.** Before this tool changes any file, it saves the original.

| Flag | What it does |
|---|---|
| `--dry-run` | Print what would happen, change nothing |
| `--yes` | Auto-confirm all prompts (for scripts/automation) |

```bash
# See what maximum-privacy would do without touching anything
./bin/linux-extra-security --dry-run --yes guided maximum-privacy
```

---

### Guided and profile commands

```bash
# Open the guided menu
./bin/linux-extra-security

# Run a specific guided workflow
./bin/linux-extra-security guided <workflow>
# workflows: privacy-baseline, desktop-hardening, vpn-friendly-lockdown, maximum-privacy, rollback

# Preview a profile
./bin/linux-extra-security profile plan <name>

# Apply a profile
./bin/linux-extra-security profile apply <name>
```

---

### Module commands

Each module supports `plan`, `apply`, and `status` subcommands.

#### DNS

```bash
./bin/linux-extra-security dns status          # Show current DNS config
./bin/linux-extra-security dns configure       # Interactive DNS setup
./bin/linux-extra-security dns verify          # Test for DNS leaks
```

Supported providers: `NextDNS`, `Quad9`, `AdGuard`, `Cloudflare`, `Custom`

#### Firewall (UFW)

```bash
./bin/linux-extra-security firewall status                # Show active rules
./bin/linux-extra-security firewall plan desktop-safe     # Preview a profile
./bin/linux-extra-security firewall apply desktop-safe    # Apply outbound rules
./bin/linux-extra-security firewall verify                # Test HTTPS and DNS egress
```

Available profiles: `desktop-safe`, `balanced`, `vpn-friendly`, `locked-down`, `travel-mode`, `server-minimal`

#### Portmaster

```bash
./bin/linux-extra-security portmaster status     # Show current state
./bin/linux-extra-security portmaster configure  # Interactive preset selector
./bin/linux-extra-security portmaster export     # Export config to .runtime/exports/
```

Presets: `usable` (blocks ads/trackers/malware), `aggressive` (+ fraud/tracking), `strict` (+ P2P blocking)

#### Telemetry reduction

```bash
./bin/linux-extra-security telemetry plan balanced    # Preview what will be disabled
./bin/linux-extra-security telemetry apply balanced   # Apply (disables whoopsie, geoclue, etc.)
./bin/linux-extra-security telemetry apply strict     # Also disables avahi, cups-browsed, Bluetooth
./bin/linux-extra-security telemetry status
```

#### SSH hardening

```bash
./bin/linux-extra-security ssh plan safe      # Preview changes
./bin/linux-extra-security ssh apply safe     # Disable root login, limit auth tries
./bin/linux-extra-security ssh status
```

#### Automatic security updates

```bash
./bin/linux-extra-security updates plan security-auto
./bin/linux-extra-security updates apply security-auto   # Enables unattended-upgrades
./bin/linux-extra-security updates status
```

#### AppArmor

```bash
./bin/linux-extra-security apparmor apply on       # Enable and start AppArmor
./bin/linux-extra-security apparmor apply strict   # Also enforce all existing profiles
./bin/linux-extra-security apparmor status
```

#### Fail2ban (optional — for internet-exposed machines)

```bash
./bin/linux-extra-security fail2ban apply optional   # Install and protect SSH
./bin/linux-extra-security fail2ban apply off        # Disable
./bin/linux-extra-security fail2ban status
```

#### Service pruning

```bash
./bin/linux-extra-security services plan balanced      # Preview which services will be disabled
./bin/linux-extra-security services apply balanced     # Disable avahi, cups-browsed
./bin/linux-extra-security services apply privacy-max  # + Bluetooth, ModemManager
./bin/linux-extra-security services status
```

#### Journald (log privacy)

```bash
./bin/linux-extra-security journald apply balanced  # Compress logs, limit retention to 2 weeks
./bin/linux-extra-security journald apply private   # Shorter retention, sealed journals
./bin/linux-extra-security journald status
```

#### Sysctl (kernel hardening)

```bash
./bin/linux-extra-security sysctl apply desktop-safe  # Safe kernel network hardening
./bin/linux-extra-security sysctl apply hardened      # Also disables ICMP redirects and BPF
./bin/linux-extra-security sysctl status
```

#### Browser alignment

```bash
./bin/linux-extra-security browser apply privacy-baseline  # Disable Firefox DoH override via policy
./bin/linux-extra-security browser status
```

> **Why this matters:** Firefox and Chrome have their own built-in encrypted DNS clients that bypass your system resolver. This module installs a managed policy that disables that bypass and forces browsers to use the system DNS you configured.

---

### Audit and reporting

```bash
# Full system audit + posture score
./bin/linux-extra-security audit

# Run all verification checks and write reports
./bin/linux-extra-security verify all

# Write a machine-readable JSON report only
./bin/linux-extra-security verify json

# Check current status of all modules at once
./bin/linux-extra-security show-status
```

---

### Rollback

> **Backups are automatic.** Before every change, the toolkit copies the original file and records the path in a manifest. You can always undo.

```bash
# List all rollback points
./bin/linux-extra-security rollback list

# Undo the most recent DNS change
./bin/linux-extra-security rollback module dns

# Undo the most recent firewall change
./bin/linux-extra-security rollback module ufw

# Undo the most recent Portmaster change
./bin/linux-extra-security rollback module portmaster

# Interactive rollback menu (choose from all modules)
./bin/linux-extra-security rollback interactive

# Preview what a rollback would do before doing it
./bin/linux-extra-security --dry-run rollback module dns
```

---

### Package installation

```bash
./bin/linux-extra-security install-tools base            # curl, jq, dnsutils, ufw
./bin/linux-extra-security install-tools host-hardening  # apparmor, fail2ban, unattended-upgrades
./bin/linux-extra-security install-tools audit           # iproute2, net-tools, procps
./bin/linux-extra-security install-tools all             # Everything above
```

### Dry-run before you commit

Any command can be previewed with `--dry-run`:

```bash
./bin/linux-extra-security --dry-run ssh apply strict
```
This prints what would happen without touching anything.

### How to undo a change

1. Open the interactive rollback menu: `./bin/linux-extra-security rollback interactive`
2. Select the module you want to restore to its original state. That's it!

Any command can be previewed with `--dry-run`:

```bash
./bin/linux-extra-security --dry-run --yes profile apply privacy-max
```

This prints every command that would run and every file that would be written, without changing anything.

### If something breaks

1. Check what module caused it: `./bin/linux-extra-security show-status`
2. List available rollback points: `./bin/linux-extra-security rollback list`
3. Restore the affected module: `./bin/linux-extra-security rollback module <name>`

Common recovery scenarios are documented in [`docs/troubleshooting.md`](docs/troubleshooting.md).

---

## Flags

| Flag | Example | Effect |
|---|---|---|
| `--dry-run` | `--dry-run profile apply privacy-max` | Preview without changing anything |
| `--yes` | `--yes guided desktop-hardening` | Auto-confirm all prompts |
| Both | `--dry-run --yes guided maximum-privacy` | Safe full preview of an entire workflow |

Flags must come **before** the command:

```bash
# Correct
./bin/linux-extra-security --dry-run --yes profile apply privacy-max

# Wrong (flags after command are ignored)
./bin/linux-extra-security profile apply privacy-max --dry-run
```

---

## Supported Systems

| System | Status |
|---|---|
| Debian 11+ | Fully supported |
| Ubuntu 22.04+ | Fully supported |
| Zorin OS 16+ | Fully supported |
| Linux Mint | Likely works (untested) |
| Pop!\_OS | Likely works (untested) |

**Requirements:**
- `apt` package manager
- `systemd` (most modern Debian-family installs)
- `systemd-resolved` (for DNS-over-TLS flows — usually pre-installed)
- `sudo` access

**Optional:**
- [Portmaster](https://safing.io/portmaster/) — enables the Portmaster module

---

## Testing

Run the test suite to verify the repo is clean and profiles are valid:

```bash
# Check shell syntax and that no secrets slipped into the repo
./tests/smoke-test.sh

# Verify all profiles have the required keys
./tests/profile-test.sh

# Run a dry-run of key commands to confirm they produce output without errors
./tests/dry-run-test.sh
```

These same tests run automatically in GitHub Actions on every push.

---

## Documentation

| Document | What it covers |
|---|---|
| [`docs/guided-flows.md`](docs/guided-flows.md) | Details on each guided workflow |
| [`docs/profiles.md`](docs/profiles.md) | How profiles work and how to create your own |
| [`docs/module-reference.md`](docs/module-reference.md) | Every command, action, and option |
| [`docs/providers.md`](docs/providers.md) | DNS provider comparison and Portmaster compatibility |
| [`docs/architecture.md`](docs/architecture.md) | How the layers fit together |
| [`docs/rollback.md`](docs/rollback.md) | Full rollback guide with manual recovery steps |
| [`docs/reporting.md`](docs/reporting.md) | Verification reports and JSON output |
| [`docs/debian-compatibility.md`](docs/debian-compatibility.md) | System assumptions and caveats |
| [`docs/troubleshooting.md`](docs/troubleshooting.md) | Common problems and how to fix them |
| [`docs/examples/`](docs/examples) | Real-world usage examples |

---

## License

Apache-2.0. See [`LICENSE`](LICENSE).

---

> **New to privacy hardening?** Start with `./bin/linux-extra-security guided privacy-baseline` — it is the safest option and gives you a meaningful improvement with minimal chance of breaking anything.
