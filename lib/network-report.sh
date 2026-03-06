#!/usr/bin/env bash
# Licensed under the Apache License, Version 2.0.

set -euo pipefail

# shellcheck source=./common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

les_network_report_human() {
  les_section "Network Report"

  if les_command_exists resolvectl; then
    les_status_line "Current DNS" "$(resolvectl status 2>/dev/null | awk -F': ' '/Current DNS Server/ {print $2; exit}' || true)"
  fi

  if les_command_exists nextdns; then
    les_status_line "NextDNS" "$(nextdns status 2>/dev/null || true)"
  fi

  if les_command_exists ufw; then
    les_status_line "UFW active" "$(sudo ufw status | awk 'NR==1 {print $2}' 2>/dev/null || echo unknown)"
  fi

  les_status_line "VPN links" "$(les_detect_vpn | paste -sd ',' - || echo none)"
}

les_network_report_json() {
  python3 - <<'PY'
import json
import subprocess

def run(cmd):
    try:
        return subprocess.check_output(cmd, text=True).strip()
    except Exception:
        return ""

data = {
    "currentDns": run(["bash", "-lc", "if command -v resolvectl >/dev/null 2>&1; then resolvectl status 2>/dev/null | awk -F': ' '/Current DNS Server/ {print $2; exit}'; fi"]),
    "nextdnsStatus": run(["bash", "-lc", "if command -v nextdns >/dev/null 2>&1; then nextdns status 2>/dev/null; fi"]),
    "ufwStatus": run(["bash", "-lc", "if command -v ufw >/dev/null 2>&1; then sudo ufw status | awk 'NR==1 {print $2}'; fi"]),
    "vpn": run(["bash", "-lc", "if command -v nmcli >/dev/null 2>&1; then nmcli -t -f NAME,TYPE connection show --active 2>/dev/null | awk -F: '$2 ~ /(vpn|wireguard)/ {print $1}' | paste -sd ',' -; fi"]),
}
print(json.dumps(data, indent=2))
PY
}
