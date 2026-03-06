#!/usr/bin/env bash
# Licensed under the Apache License, Version 2.0.

set -euo pipefail

les_coredump_plan() {
  local mode="$1"
  les_section "Core Dump Restrictions"
  case "${mode}" in
    lite)
      les_info "Plan: Lite mode (Allow core dumps but restrict access to root only)"
      ;;
    strict)
      les_info "Plan: Strict mode (Disable core dumps completely via systemd-coredump and sysctl)"
      ;;
    *)
      les_die "Unknown core dump restriction mode: ${mode}"
      ;;
  esac
}

les_coredump_apply() {
  local mode="${1:-}"

  if [[ -z "${mode}" ]]; then
    mode="$(les_choose_from_menu "Select Core Dump Restriction Mode:" \
      "lite" \
      "strict")"
  fi

  les_coredump_plan "${mode}"
  les_confirm "Apply core dump restrictions?" || return 0

  local manifest
  manifest="$(les_new_manifest "coredump")"

  local sysctl_file="/etc/sysctl.d/50-coredump.conf"
  local systemd_file="/etc/systemd/coredump.conf.d/disable.conf"

  les_record_manifest_copy "${manifest}" "${sysctl_file}"
  les_record_manifest_copy "${manifest}" "${systemd_file}"

  case "${mode}" in
    lite)
      les_info "Applying lite core dump settings (restricting permissions)..."
      les_run sudo rm -f "${systemd_file}"
      les_write_root_file "${sysctl_file}" "fs.suid_dumpable=2"
      les_run sudo sysctl -p "${sysctl_file}" || true
      ;;
    strict)
      les_info "Applying strict core dump restrictions (disabling)..."
      les_write_root_file "${sysctl_file}" "kernel.core_pattern=|/bin/false
fs.suid_dumpable=0"
      les_write_root_file "${systemd_file}" "[Coredump]
Storage=none
ProcessSizeMax=0"
      les_run sudo sysctl -p "${sysctl_file}" || true
      les_run sudo systemctl daemon-reload || true
      ;;
    *)
      les_die "Unknown core dump restriction mode: ${mode}"
      ;;
  esac

  les_info "Core dump restrictions applied."
}

les_coredump_status() {
  les_section "Core Dump Status"
  if [[ -f "/etc/sysctl.d/50-coredump.conf" ]] && grep -q "kernel.core_pattern=|/bin/false" "/etc/sysctl.d/50-coredump.conf"; then
    les_status_line "Core Dumps" "Disabled (Strict)"
  elif [[ -f "/etc/sysctl.d/50-coredump.conf" ]] && grep -q "fs.suid_dumpable=2" "/etc/sysctl.d/50-coredump.conf"; then
    les_status_line "Core Dumps" "Restricted (Lite)"
  else
    les_status_line "Core Dumps" "Enabled (Default)"
  fi
}
