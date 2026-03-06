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

  ALLOW_TCP_IN=""
  ALLOW_UDP_IN=""
  ALLOW_TCP_OUT=""
  ALLOW_UDP_OUT=""
  DENY_OUT=""
  ALLOW_LAN="no"

  # shellcheck disable=SC1090
  source "${profile_file}"
}

les_ufw_warn_if_nftables_present() {
  if les_command_exists nft && nft list ruleset 2>/dev/null | grep -q 'table '; then
    les_warn "Detected an existing nftables ruleset. Review layering UFW on top of nftables before applying."
  fi
}

les_ufw_backup() {
  local manifest
  manifest="$(les_new_manifest ufw)"
  les_ensure_runtime
  les_record_manifest_copy "${manifest}" "/etc/ufw"
  les_write_state_file "latest-ufw-manifest" "${manifest}"
  les_info "Recorded rollback manifest: ${manifest}"
}

les_ufw_plan() {
  local profile_name="$1"
  local rule

  les_ufw_load_profile "${profile_name}"
  les_section "UFW Plan"
  les_status_line "Profile" "${profile_name}"
  les_status_line "Description" "${DESCRIPTION}"
  les_status_line "Allow TCP out" "${ALLOW_TCP_OUT:-none}"
  les_status_line "Allow UDP out" "${ALLOW_UDP_OUT:-none}"
  les_status_line "Allow TCP in" "${ALLOW_TCP_IN:-none}"
  les_status_line "Allow UDP in" "${ALLOW_UDP_IN:-none}"
  les_status_line "Deny out" "${DENY_OUT:-none}"
  if [[ "${ALLOW_LAN:-no}" == "yes" ]]; then
    les_status_line "LAN access" "Enabled for RFC1918 private ranges"
  fi
  for rule in ${EXPLANATIONS:-}; do
    les_note "${rule}"
  done
}

les_ufw_apply_profile() {
  local profile_name="$1"
  local tcp_port
  local udp_port
  local deny_port

  les_require_sudo
  les_ufw_load_profile "${profile_name}"
  les_ufw_warn_if_nftables_present
  les_ufw_backup

  if [[ -n "${SSH_CONNECTION:-}" ]]; then
    les_warn "Detected SSH session. Review outbound and inbound rules carefully before continuing."
  fi
  les_warn "${DESCRIPTION}"
  les_confirm "Apply the ${profile_name} UFW profile?" || return 1

  les_run sudo ufw --force reset
  les_run sudo ufw default deny incoming
  les_run sudo ufw default deny outgoing
  les_run sudo ufw allow in on lo
  les_run sudo ufw allow out on lo

  for tcp_port in ${ALLOW_TCP_OUT}; do
    les_run sudo ufw allow out "${tcp_port}/tcp"
  done
  for udp_port in ${ALLOW_UDP_OUT}; do
    les_run sudo ufw allow out "${udp_port}/udp"
  done
  for tcp_port in ${ALLOW_TCP_IN}; do
    les_run sudo ufw allow in "${tcp_port}/tcp"
  done
  for udp_port in ${ALLOW_UDP_IN}; do
    les_run sudo ufw allow in "${udp_port}/udp"
  done
  for deny_port in ${DENY_OUT}; do
    les_run sudo ufw deny out "${deny_port}"
  done

  if [[ "${ALLOW_LAN:-no}" == "yes" ]]; then
    les_run sudo ufw allow out to 10.0.0.0/8
    les_run sudo ufw allow out to 172.16.0.0/12
    les_run sudo ufw allow out to 192.168.0.0/16
  fi

  les_run sudo ufw --force enable
}

les_ufw_configure_interactive() {
  local profile
  profile="$(les_choose_from_menu "Choose a UFW profile" "desktop-safe" "balanced" "vpn-friendly" "locked-down" "travel-mode" "server-minimal")"
  les_ufw_plan "${profile}"
  les_ufw_apply_profile "${profile}"
  les_ufw_show_status
}

les_ufw_apply_profile_from_active_profile() {
  local profile_name="$1"
  les_load_profile "${profile_name}"
  les_ufw_plan "${UFW_PROFILE}"
  les_ufw_apply_profile "${UFW_PROFILE}"
}

les_ufw_verify() {
  les_section "UFW Verification"
  if les_command_exists curl; then
    if curl -fsSL https://example.com >/dev/null 2>&1; then
      les_info "HTTPS egress is working."
    else
      les_warn "HTTPS egress failed."
    fi
  fi
  if les_command_exists dig; then
    if dig @1.1.1.1 example.com +time=2 +tries=1 >/dev/null 2>&1; then
      les_warn "Plaintext DNS egress is still reachable."
    else
      les_info "Plaintext DNS egress appears blocked."
    fi
  fi
}

les_ufw_show_status() {
  les_section "UFW Status"
  if les_command_exists ufw; then
    sudo ufw status verbose
  else
    les_status_line "UFW" "not installed"
  fi
}
