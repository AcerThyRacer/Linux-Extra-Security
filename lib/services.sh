#!/usr/bin/env bash
# Licensed under the Apache License, Version 2.0.

set -euo pipefail

# shellcheck source=./common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

les_services_profile_targets() {
  case "${1:-balanced}" in
    lite)
      printf '%s\n' cups-browsed
      ;;
    balanced)
      printf '%s\n' avahi-daemon cups-browsed
      ;;
    vpn-friendly)
      printf '%s\n' avahi-daemon cups-browsed
      ;;
    privacy-max)
      printf '%s\n' avahi-daemon cups-browsed bluetooth ModemManager
      ;;
    developer)
      printf '%s\n' cups-browsed
      ;;
    *)
      les_die "Unknown services profile: $1"
      ;;
  esac
}

les_services_plan() {
  local profile="${1:-balanced}"
  les_section "Services Plan"
  les_status_line "Profile" "${profile}"
  les_services_profile_targets "${profile}" | sed 's/^/  - /'
}

les_services_apply() {
  local profile="${1:-}"

  if [[ -z "${profile}" ]]; then
    profile="$(les_choose_from_menu "Select Services Profile:" \
      "lite" \
      "balanced" \
      "vpn-friendly" \
      "developer" \
      "privacy-max")"
  fi

  les_services_plan "${profile}"
  les_confirm "Apply services profile?" || return 0

  local service_name

  while IFS= read -r service_name; do
    if systemctl list-unit-files 2>/dev/null | grep -q "^${service_name}\.service"; then
      les_run sudo systemctl disable --now "${service_name}.service"
    fi
  done < <(les_services_profile_targets "${profile}")

  les_write_state_file "services-profile" "${profile}"
}

les_services_status() {
  local saved_profile
  saved_profile="$(les_read_state_file "services-profile" || true)"
  les_section "Services Status"
  les_status_line "Recorded profile" "${saved_profile:-none}"
  for service_name in avahi-daemon cups-browsed bluetooth ModemManager; do
    les_status_line "${service_name}" "$(les_service_state "${service_name}")"
  done
}
