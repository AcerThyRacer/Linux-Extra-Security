#!/usr/bin/env bash
# Licensed under the Apache License, Version 2.0.

set -euo pipefail

# shellcheck source=./common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

LES_SSH_DROPIN="/etc/ssh/sshd_config.d/99-linux-extra-security.conf"

les_ssh_plan() {
  local mode="${1:-safe}"
  les_section "SSH Hardening Plan"
  les_status_line "Mode" "${mode}"
  les_status_line "Drop-in" "${LES_SSH_DROPIN}"
  les_status_line "Changes" "Disable root login, limit auth attempts, prefer protocol defaults"
}

les_ssh_dropin_content() {
  local mode="${1:-safe}"
  cat <<EOF
# Managed by Linux Extra Security.
PermitRootLogin no
MaxAuthTries 3
X11Forwarding no
ClientAliveInterval 300
ClientAliveCountMax 2
LoginGraceTime 30
$(if [[ "${mode}" == "safe" ]]; then printf '%s\n' 'PasswordAuthentication yes'; else printf '%s\n' 'PasswordAuthentication no'; fi)
EOF
}

les_ssh_apply() {
  local mode="${1:-safe}"
  local manifest

  manifest="$(les_new_manifest ssh)"
  les_write_state_file "latest-ssh-manifest" "${manifest}"
  if [[ -e "${LES_SSH_DROPIN}" ]]; then
    les_record_manifest_copy "${manifest}" "${LES_SSH_DROPIN}"
  fi
  les_write_root_file "${LES_SSH_DROPIN}" "$(les_ssh_dropin_content "${mode}")"

  if ! les_is_dry_run && les_command_exists sshd; then
    sudo sshd -t
    les_run sudo systemctl reload ssh
  fi
}

les_ssh_status() {
  les_section "SSH Status"
  les_status_line "Service" "$(les_service_state ssh)"
  les_status_line "Drop-in" "$(if [[ -r "${LES_SSH_DROPIN}" ]]; then echo present; else echo absent; fi)"
  if [[ -r "${LES_SSH_DROPIN}" ]]; then
    awk 'NF {print "  " $0}' "${LES_SSH_DROPIN}"
  fi
}
