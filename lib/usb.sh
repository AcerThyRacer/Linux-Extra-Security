#!/usr/bin/env bash
# Licensed under the Apache License, Version 2.0.

set -euo pipefail

les_usb_plan() {
  local mode="$1"
  les_section "USB Storage Restriction"
  case "${mode}" in
    lite)
      les_info "Plan: Lite mode (Allow USB storage, removing strict block)"
      ;;
    strict)
      les_info "Plan: Strict mode (Disable USB storage completely via modprobe)"
      ;;
    *)
      les_die "Unknown USB restriction mode: ${mode}"
      ;;
  esac
}

les_usb_apply() {
  local mode="${1:-}"

  if [[ -z "${mode}" ]]; then
    mode="$(les_choose_from_menu "Select USB Storage Restriction Mode:" \
      "lite" \
      "strict")"
  fi

  les_usb_plan "${mode}"
  les_confirm "Apply USB storage restriction?" || return 0

  local manifest
  manifest="$(les_new_manifest "usb")"

  case "${mode}" in
    lite)
      les_info "Applying lite USB settings (removing strict block if present)..."
      if [[ -f "/etc/modprobe.d/disable-usb-storage.conf" ]]; then
        les_record_manifest_copy "${manifest}" "/etc/modprobe.d/disable-usb-storage.conf"
        les_run sudo rm -f "/etc/modprobe.d/disable-usb-storage.conf"
      fi
      ;;
    strict)
      les_info "Applying strict USB storage block..."
      les_record_manifest_copy "${manifest}" "/etc/modprobe.d/disable-usb-storage.conf"
      les_write_root_file "/etc/modprobe.d/disable-usb-storage.conf" "install usb-storage /bin/true"
      ;;
    *)
      les_die "Unknown USB restriction mode: ${mode}"
      ;;
  esac

  les_info "USB storage restriction applied."
}

les_usb_status() {
  les_section "USB Storage Status"
  if [[ -f "/etc/modprobe.d/disable-usb-storage.conf" ]] && grep -q "install usb-storage /bin/true" "/etc/modprobe.d/disable-usb-storage.conf"; then
    les_status_line "USB Storage" "Disabled (Strict)"
  else
    les_status_line "USB Storage" "Enabled (Lite/Default)"
  fi
}
