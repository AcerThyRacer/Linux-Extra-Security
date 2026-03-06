#!/usr/bin/env bash
# Licensed under the Apache License, Version 2.0.

set -euo pipefail

# shellcheck source=./common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"
# shellcheck source=./package-install.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/package-install.sh"

les_apparmor_plan() {
  local mode="${1:-on}"
  les_section "AppArmor Plan"
  les_status_line "Mode" "${mode}"
  les_status_line "Packages" "apparmor, apparmor-utils"
}

les_apparmor_apply() {
  local mode="${1:-}"

  if [[ -z "${mode}" ]]; then
    mode="$(les_choose_from_menu "Select AppArmor Mode:" \
      "on" \
      "strict")"
  fi

  les_apparmor_plan "${mode}"
  les_confirm "Apply AppArmor mode?" || return 0

  case "${mode}" in
    on|strict) ;;
    *)
      les_die "Unknown AppArmor mode: ${mode}"
      ;;
  esac

  les_pkg_install_if_missing apparmor apparmor-utils
  les_run sudo systemctl enable --now apparmor
  if ! les_is_dry_run && les_command_exists aa-enforce && [[ "${mode}" == "strict" ]]; then
    sudo aa-enforce /etc/apparmor.d/* >/dev/null 2>&1 || true
  fi
}

les_apparmor_status() {
  les_section "AppArmor Status"
  les_status_line "Service" "$(les_service_state apparmor)"
  if les_command_exists aa-status; then
    aa-status 2>/dev/null || true
  fi
}
