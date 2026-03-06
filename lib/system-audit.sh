#!/usr/bin/env bash
# Licensed under the Apache License, Version 2.0.

set -euo pipefail

# shellcheck source=./common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

les_audit_detect_dns_stack() {
  if les_command_exists nextdns && nextdns status >/dev/null 2>&1; then
    printf 'nextdns-cli\n'
  elif les_command_exists resolvectl; then
    printf 'systemd-resolved\n'
  else
    printf 'unknown\n'
  fi
}

les_audit_posture_score() {
  local score=0

  [[ "$(les_service_state systemd-resolved)" == "active" ]] && score=$((score + 10))
  [[ "$(les_service_state ufw)" == "active" ]] && score=$((score + 15))
  [[ "$(les_service_state apparmor)" == "active" ]] && score=$((score + 15))
  [[ "$(les_service_state fail2ban)" == "active" ]] && score=$((score + 10))
  [[ -f /etc/apt/apt.conf.d/20auto-upgrades ]] && score=$((score + 10))
  [[ -f /etc/sysctl.d/99-linux-extra-security.conf ]] && score=$((score + 15))
  [[ -f /etc/systemd/journald.conf.d/99-linux-extra-security.conf ]] && score=$((score + 10))
  [[ -f /etc/ssh/sshd_config.d/99-linux-extra-security.conf ]] && score=$((score + 15))

  printf '%s\n' "${score}"
}

les_system_audit_report() {
  les_section "System Audit"
  les_status_line "Toolkit version" "${LES_VERSION}"
  les_status_line "Detected OS" "$(les_detect_os)"
  les_status_line "DNS stack" "$(les_audit_detect_dns_stack)"
  les_status_line "VPN detected" "$(les_detect_vpn | paste -sd ',' - || echo none)"
  les_status_line "UFW" "$(les_service_state ufw)"
  les_status_line "AppArmor" "$(les_service_state apparmor)"
  les_status_line "Fail2ban" "$(les_service_state fail2ban)"
  les_status_line "Resolved" "$(les_service_state systemd-resolved)"
  les_status_line "Posture score" "$(les_audit_posture_score)/100"
}

les_system_audit_json() {
  python3 - <<'PY'
import json
import os
import subprocess

def run(cmd):
    try:
        return subprocess.check_output(cmd, text=True).strip()
    except Exception:
        return ""

def service_state(name):
    active = subprocess.run(["systemctl", "is-active", "--quiet", name], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    if active.returncode == 0:
        return "active"
    unit_files = run(["bash", "-lc", f"systemctl list-unit-files 2>/dev/null | awk '/^{name}[.]service/ {{print $1; exit}}'"])
    return "inactive" if unit_files else "not-installed"

score = 0
if service_state("systemd-resolved") == "active":
    score += 10
if service_state("ufw") == "active":
    score += 15
if service_state("apparmor") == "active":
    score += 15
if service_state("fail2ban") == "active":
    score += 10
if os.path.exists("/etc/apt/apt.conf.d/20auto-upgrades"):
    score += 10
if os.path.exists("/etc/sysctl.d/99-linux-extra-security.conf"):
    score += 15
if os.path.exists("/etc/systemd/journald.conf.d/99-linux-extra-security.conf"):
    score += 10
if os.path.exists("/etc/ssh/sshd_config.d/99-linux-extra-security.conf"):
    score += 15

data = {
    "toolkitVersion": os.environ.get("LES_VERSION", ""),
    "os": run(["bash", "-lc", "source /etc/os-release && printf '%s:%s' \"$ID\" \"$VERSION_ID\""]),
    "vpn": run(["bash", "-lc", "if command -v nmcli >/dev/null 2>&1; then nmcli -t -f NAME,TYPE connection show --active 2>/dev/null | awk -F: '$2 ~ /(vpn|wireguard)/ {print $1}' | paste -sd ',' -; fi"]),
    "postureScore": score,
    "services": {
        "ufw": service_state("ufw"),
        "apparmor": service_state("apparmor"),
        "fail2ban": service_state("fail2ban"),
        "systemd-resolved": service_state("systemd-resolved"),
    },
}
print(json.dumps(data, indent=2))
PY
}
