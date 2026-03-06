#!/usr/bin/env bash
# Licensed under the Apache License, Version 2.0.

set -euo pipefail

# shellcheck source=./common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"
# shellcheck source=./package-install.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/package-install.sh"

LES_FAIL2BAN_JAIL="/etc/fail2ban/jail.d/99-linux-extra-security.conf"

les_fail2ban_plan() {
  local mode="${1:-optional}"
  les_section "Fail2ban Plan"
  les_status_line "Mode" "${mode}"
  les_status_line "Jail file" "${LES_FAIL2BAN_JAIL}"
}

les_fail2ban_apply() {
  local mode="${1:-optional}"
  local manifest
  local content

  case "${mode}" in
    off)
      les_run sudo systemctl disable --now fail2ban
      return 0
      ;;
    optional|sshd)
      ;;
    *)
      les_die "Unknown fail2ban mode: ${mode}"
      ;;
  esac

  les_pkg_install_if_missing fail2ban
  manifest="$(les_new_manifest fail2ban)"
  les_write_state_file "latest-fail2ban-manifest" "${manifest}"
  [[ -e "${LES_FAIL2BAN_JAIL}" ]] && les_record_manifest_copy "${manifest}" "${LES_FAIL2BAN_JAIL}"

  content='[sshd]
enabled = true
port = ssh
backend = systemd
maxretry = 5
findtime = 10m
bantime = 1h'

  les_write_root_file "${LES_FAIL2BAN_JAIL}" "${content}"
  les_run sudo systemctl enable --now fail2ban
}

les_fail2ban_status() {
  les_section "Fail2ban Status"
  les_status_line "Service" "$(les_service_state fail2ban)"
  les_status_line "Jail file" "$(if [[ -r "${LES_FAIL2BAN_JAIL}" ]]; then echo present; else echo absent; fi)"
}
