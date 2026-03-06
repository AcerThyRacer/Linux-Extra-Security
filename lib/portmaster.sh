#!/usr/bin/env bash
# Licensed under the Apache License, Version 2.0.

set -euo pipefail

# shellcheck source=./common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

LES_PORTMASTER_CONFIG="/var/lib/portmaster/config.json"

les_portmaster_installed() {
  les_command_exists portmaster || les_command_exists portmaster-start || systemctl list-unit-files 2>/dev/null | grep -q '^portmaster\.service'
}

les_portmaster_health() {
  if systemctl is-active --quiet portmaster; then
    printf 'running\n'
  elif systemctl list-unit-files 2>/dev/null | grep -q '^portmaster\.service'; then
    printf 'installed-not-running\n'
  else
    printf 'not-installed\n'
  fi
}

les_portmaster_detect_nextdns_mode() {
  if [[ -r /etc/nextdns.conf ]] && grep -q '^listen 127\.0\.0\.1:' /etc/nextdns.conf; then
    grep '^listen 127\.0\.0\.1:' /etc/nextdns.conf | awk -F: '{print $2}' | head -n 1
  fi
}

les_portmaster_apply_config() {
  local preset="$1"
  local nextdns_port="$2"
  local prevent_bypass="$3"

  les_require_sudo
  les_backup_file "${LES_PORTMASTER_CONFIG}"

  sudo python3 - "${LES_PORTMASTER_CONFIG}" "${preset}" "${nextdns_port}" "${prevent_bypass}" <<'PY'
import json
import pathlib
import sys

config_path = pathlib.Path(sys.argv[1])
preset = sys.argv[2]
nextdns_port = sys.argv[3]
prevent_bypass = sys.argv[4].lower() == "true"

lists_by_preset = {
    "usable": ["telemetry.txt", "ads.txt", "analytics.txt", "malware.txt", "phishing.txt"],
    "aggressive": ["telemetry.txt", "ads.txt", "analytics.txt", "malware.txt", "phishing.txt", "fraud.txt", "tracking-other.txt"],
    "strict": ["telemetry.txt", "ads.txt", "analytics.txt", "malware.txt", "phishing.txt", "fraud.txt", "tracking-other.txt"],
}

if config_path.exists():
    data = json.loads(config_path.read_text())
else:
    data = {}

data.setdefault("dns", {})
data.setdefault("filter", {})

if nextdns_port:
    data["dns"]["nameservers"] = [f"tcp://127.0.0.1:{nextdns_port}", f"dns://127.0.0.1:{nextdns_port}"]

data["dns"]["useStaleCache"] = True
data["filter"]["lists"] = lists_by_preset[preset]
data["filter"]["blockInbound"] = True
data["filter"]["preventBypassing"] = prevent_bypass

if preset == "strict" and not nextdns_port:
    data["filter"]["blockP2P"] = True
else:
    data["filter"].pop("blockP2P", None)

config_path.write_text(json.dumps(data, indent=2) + "\n")
PY

  sudo systemctl restart portmaster
}

les_portmaster_configure_interactive() {
  local health
  local preset
  local nextdns_port
  local prevent_bypass

  if ! les_portmaster_installed; then
    les_die "Portmaster does not appear to be installed on this system."
  fi

  health="$(les_portmaster_health)"
  les_info "Portmaster status: ${health}"

  preset="$(les_choose_from_menu "Choose a Portmaster preset" "usable" "aggressive" "strict")"
  nextdns_port="$(les_portmaster_detect_nextdns_mode || true)"
  prevent_bypass="true"

  if [[ -n "${nextdns_port}" ]]; then
    les_warn "Detected a localhost NextDNS listener on port ${nextdns_port}."
    les_warn "Portmaster bypass prevention can break this architecture."
    prevent_bypass="false"
  elif [[ "${preset}" != "strict" ]]; then
    if ! les_confirm "Enable Portmaster DNS bypass prevention?"; then
      prevent_bypass="false"
    fi
  fi

  les_portmaster_apply_config "${preset}" "${nextdns_port}" "${prevent_bypass}"
  les_portmaster_show_status
}

les_portmaster_show_status() {
  les_status_line "Portmaster" "$(les_portmaster_health)"
  if [[ -r "${LES_PORTMASTER_CONFIG}" ]]; then
    les_status_line "Portmaster config" "${LES_PORTMASTER_CONFIG}"
  fi
}
