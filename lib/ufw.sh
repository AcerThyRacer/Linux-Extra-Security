#!/usr/bin/env bash
# Licensed under the Apache License, Version 2.0.

set -euo pipefail

# shellcheck source=./common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

LES_UFW_PROFILE_DIR="${LES_REPO_ROOT}/templates/ufw-profiles"

les_ufw_load_profile() {
  local profile_name="$1"
  local profile_file="${LES_UFW_PROFILE_DIR}/${profile_name}.env"

  [[ -r "${profile_file}" ]] || les_die "UFW profile not found: ${profile_name}"

  # shellcheck disable=SC1090
  source "${profile_file}"
}

les_ufw_backup() {
  local manifest="${LES_STATE_ROOT}/ufw-$(les_timestamp).manifest"
  les_ensure_runtime
  les_record_manifest_copy "${manifest}" "/etc/ufw" 
  les_write_state_file "latest-ufw-manifest" "${manifest}"
  les_info "Recorded rollback manifest: ${manifest}"
}

les_ufw_apply_profile() {
  local profile_name="$1"
  local tcp_port
  local udp_port
  local deny_port

  les_require_sudo
  les_ufw_load_profile "${profile_name}"
  les_ufw_backup

  if [[ -n "${SSH_CONNECTION:-}" ]]; then
    les_warn "Detected SSH session. Review outbound and inbound rules carefully before continuing."
  fi
  les_warn "${DESCRIPTION}"
  les_confirm "Apply the ${profile_name} UFW profile?" || return 1

  sudo ufw --force reset
  sudo ufw default deny incoming
  sudo ufw default deny outgoing
  sudo ufw allow in on lo
  sudo ufw allow out on lo

  for tcp_port in ${ALLOW_TCP_OUT}; do
    sudo ufw allow out "${tcp_port}/tcp"
  done
  for udp_port in ${ALLOW_UDP_OUT}; do
    sudo ufw allow out "${udp_port}/udp"
  done
  for deny_port in ${DENY_OUT}; do
    sudo ufw deny out "${deny_port}"
  done

  sudo ufw --force enable
}

les_ufw_configure_interactive() {
  local profile
  profile="$(les_choose_from_menu "Choose a UFW profile" "balanced" "vpn-friendly" "strict")"
  les_ufw_apply_profile "${profile}"
  les_ufw_show_status
}

les_ufw_show_status() {
  if les_command_exists ufw; then
    les_info "UFW status"
    sudo ufw status verbose
  else
    les_status_line "UFW" "not installed"
  fi
}
