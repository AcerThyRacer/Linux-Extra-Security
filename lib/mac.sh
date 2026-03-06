#!/usr/bin/env bash
# Licensed under the Apache License, Version 2.0.

set -euo pipefail

les_mac_plan() {
  local mode="$1"
  les_section "MAC Address Randomization"
  case "${mode}" in
    lite)
      les_info "Plan: Lite mode (Randomize MAC per connection/SSID)"
      ;;
    strict)
      les_info "Plan: Strict mode (Randomize MAC every time you connect)"
      ;;
    *)
      les_die "Unknown MAC randomization mode: ${mode}"
      ;;
  esac
}

les_mac_apply() {
  local mode="${1:-}"

  if [[ -z "${mode}" ]]; then
    mode="$(les_choose_from_menu "Select MAC Address Randomization Mode:" \
      "lite" \
      "strict")"
  fi

  les_mac_plan "${mode}"
  les_confirm "Apply MAC randomization?" || return 0

  local manifest
  manifest="$(les_new_manifest "mac")"

  local conf_file="/etc/NetworkManager/conf.d/mac-randomization.conf"
  les_record_manifest_copy "${manifest}" "${conf_file}"

  case "${mode}" in
    lite)
      les_info "Applying lite MAC randomization (per connection)..."
      les_write_root_file "${conf_file}" "[device]
wifi.scan-rand-mac-address=yes

[connection]
wifi.cloned-mac-address=stable
ethernet.cloned-mac-address=stable"
      ;;
    strict)
      les_info "Applying strict MAC randomization (every time)..."
      les_write_root_file "${conf_file}" "[device]
wifi.scan-rand-mac-address=yes

[connection]
wifi.cloned-mac-address=random
ethernet.cloned-mac-address=random"
      ;;
    *)
      les_die "Unknown MAC randomization mode: ${mode}"
      ;;
  esac

  if ! les_is_dry_run; then
    les_info "Restarting NetworkManager to apply changes..."
    les_run sudo systemctl restart NetworkManager || true
  fi

  les_info "MAC randomization applied."
}

les_mac_status() {
  les_section "MAC Address Randomization Status"
  if [[ -f "/etc/NetworkManager/conf.d/mac-randomization.conf" ]]; then
    if grep -q "cloned-mac-address=random" "/etc/NetworkManager/conf.d/mac-randomization.conf"; then
      les_status_line "MAC Randomization" "Strict (Random Every Time)"
    elif grep -q "cloned-mac-address=stable" "/etc/NetworkManager/conf.d/mac-randomization.conf"; then
      les_status_line "MAC Randomization" "Lite (Stable Per Connection)"
    else
      les_status_line "MAC Randomization" "Custom Configuration"
    fi
  else
    les_status_line "MAC Randomization" "Not Configured (Default)"
  fi
}
