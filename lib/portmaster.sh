#!/usr/bin/env bash
# Licensed under the Apache License, Version 2.0.

set -euo pipefail

# shellcheck source=./common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

LES_PORTMASTER_CONFIG="/var/lib/portmaster/config.json"
LES_PORTMASTER_EXPORT_DIR="${LES_RUNTIME_DIR}/exports"

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

les_portmaster_valid_filter_lists() {
  printf '%s\n' TRAC MAL BAD UNBREAK
}

les_portmaster_detect_nextdns_mode() {
  if [[ -r /etc/nextdns.conf ]] && grep -q '^listen 127\.0\.0\.1:' /etc/nextdns.conf; then
    awk '/^listen 127\.0\.0\.1:/ {split($2, value, ":"); print value[2]; exit}' /etc/nextdns.conf
  fi
}

les_portmaster_detect_compatibility_mode() {
  local nextdns_port
  nextdns_port="$(les_portmaster_detect_nextdns_mode || true)"
  if [[ -n "${nextdns_port}" ]]; then
    printf 'nextdns-forwarder:%s\n' "${nextdns_port}"
  elif [[ -n "$(les_detect_vpn | paste -sd ',' -)" ]]; then
    printf 'vpn\n'
  else
    printf 'native\n'
  fi
}

les_portmaster_plan() {
  local preset="$1"
  local compatibility

  compatibility="$(les_portmaster_detect_compatibility_mode)"
  les_section "Portmaster Plan"
  les_status_line "Preset" "${preset}"
  les_status_line "Current health" "$(les_portmaster_health)"
  les_status_line "Compatibility" "${compatibility}"
  les_status_line "Filter lists" "$(les_portmaster_valid_filter_lists | paste -sd ',' -)"
  case "${compatibility}" in
    nextdns-forwarder:*)
      les_warn "Portmaster will use localhost DNS forwarding and disable bypass prevention."
      ;;
    vpn)
      les_warn "VPN detected. Review DNS bypass prevention after applying."
      ;;
  esac
}

les_portmaster_apply_config() {
  local preset="$1"
  local nextdns_port="$2"
  local prevent_bypass="$3"
  local manifest="$4"

  les_require_sudo
  [[ -e "${LES_PORTMASTER_CONFIG}" ]] && les_record_manifest_copy "${manifest}" "${LES_PORTMASTER_CONFIG}"

  if les_is_dry_run; then
    les_info "Would update ${LES_PORTMASTER_CONFIG} with preset=${preset}, nextdns_port=${nextdns_port:-none}, prevent_bypass=${prevent_bypass}"
    return 0
  fi

  sudo python3 - "${LES_PORTMASTER_CONFIG}" "${preset}" "${nextdns_port}" "${prevent_bypass}" <<'PY'
import json
import pathlib
import sys

config_path = pathlib.Path(sys.argv[1])
preset = sys.argv[2]
nextdns_port = sys.argv[3]
prevent_bypass = sys.argv[4].lower() == "true"

lists_by_preset = {
    "usable": ["TRAC", "MAL", "BAD", "UNBREAK"],
    "aggressive": ["TRAC", "MAL", "BAD", "UNBREAK"],
    "strict": ["TRAC", "MAL", "BAD", "UNBREAK"],
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

  les_run sudo systemctl restart portmaster
}

les_portmaster_apply() {
  local preset="$1"
  local health
  local nextdns_port
  local prevent_bypass
  local manifest

  if ! les_portmaster_installed; then
    les_warn "Portmaster does not appear to be installed on this system. Skipping Portmaster apply."
    return 0
  fi

  health="$(les_portmaster_health)"
  les_info "Portmaster status: ${health}"
  nextdns_port="$(les_portmaster_detect_nextdns_mode || true)"
  prevent_bypass="true"
  manifest="$(les_new_manifest portmaster)"
  les_write_state_file "latest-portmaster-manifest" "${manifest}"

  if [[ -n "${nextdns_port}" ]]; then
    les_warn "Detected a localhost NextDNS listener on port ${nextdns_port}."
    les_warn "Portmaster bypass prevention can break this architecture."
    prevent_bypass="false"
  elif [[ -n "$(les_detect_vpn | paste -sd ',' -)" ]]; then
    prevent_bypass="false"
    les_warn "VPN detected. Starting with bypass prevention disabled is safer."
  elif [[ "${preset}" != "strict" ]] && ! les_confirm "Enable Portmaster DNS bypass prevention?"; then
    prevent_bypass="false"
  fi

  les_portmaster_apply_config "${preset}" "${nextdns_port}" "${prevent_bypass}" "${manifest}"
}

les_portmaster_apply_profile() {
  local profile_name="$1"
  les_load_profile "${profile_name}"
  les_portmaster_plan "${PORTMASTER_PRESET}"
  les_portmaster_apply "${PORTMASTER_PRESET}"
}

les_portmaster_configure_interactive() {
  local preset
  preset="$(les_choose_from_menu "Choose a Portmaster preset" "usable" "aggressive" "strict")"
  les_portmaster_plan "${preset}"
  les_confirm "Apply this Portmaster plan?" || return 1
  les_portmaster_apply "${preset}"
  les_portmaster_show_status
}

les_portmaster_export_config() {
  local output_path

  [[ -r "${LES_PORTMASTER_CONFIG}" ]] || les_die "Portmaster config not found: ${LES_PORTMASTER_CONFIG}"
  mkdir -p "${LES_PORTMASTER_EXPORT_DIR}"
  output_path="${LES_PORTMASTER_EXPORT_DIR}/portmaster-config-$(les_timestamp).json"
  cp "${LES_PORTMASTER_CONFIG}" "${output_path}"
  les_info "Exported Portmaster config to ${output_path}"
}

les_portmaster_show_status() {
  les_section "Portmaster Status"
  les_status_line "Portmaster" "$(les_portmaster_health)"
  les_status_line "Compatibility" "$(les_portmaster_detect_compatibility_mode)"
  if [[ -r "${LES_PORTMASTER_CONFIG}" ]]; then
    les_status_line "Portmaster config" "${LES_PORTMASTER_CONFIG}"
    python3 - "${LES_PORTMASTER_CONFIG}" <<'PY'
import json
import sys

path = sys.argv[1]
data = json.load(open(path))
print(f"{'Nameservers':24} {', '.join(data.get('dns', {}).get('nameservers', []))}")
print(f"{'Bypass prevention':24} {data.get('filter', {}).get('preventBypassing', '')}")
print(f"{'Block inbound':24} {data.get('filter', {}).get('blockInbound', '')}")
print(f"{'Filter lists':24} {', '.join(data.get('filter', {}).get('lists', []))}")
PY
  fi
}
