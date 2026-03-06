#!/usr/bin/env bash
# Licensed under the Apache License, Version 2.0.

set -euo pipefail

# shellcheck source=./common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

LES_SYSCTL_DROPIN="/etc/sysctl.d/99-linux-extra-security.conf"

les_sysctl_plan() {
  local profile="${1:-desktop-safe}"
  les_section "Sysctl Plan"
  les_status_line "Profile" "${profile}"
  les_status_line "Drop-in" "${LES_SYSCTL_DROPIN}"
}

les_sysctl_content() {
  case "${1:-desktop-safe}" in
    desktop-safe)
      cat <<'EOF'
kernel.kptr_restrict = 2
kernel.dmesg_restrict = 1
net.ipv4.tcp_syncookies = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
EOF
      ;;
    hardened)
      cat <<'EOF'
kernel.kptr_restrict = 2
kernel.dmesg_restrict = 1
kernel.unprivileged_bpf_disabled = 1
net.ipv4.tcp_syncookies = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
EOF
      ;;
    *)
      les_die "Unknown sysctl profile: $1"
      ;;
  esac
}

les_sysctl_apply() {
  local profile="${1:-desktop-safe}"
  local manifest

  manifest="$(les_new_manifest sysctl)"
  les_write_state_file "latest-sysctl-manifest" "${manifest}"
  [[ -e "${LES_SYSCTL_DROPIN}" ]] && les_record_manifest_copy "${manifest}" "${LES_SYSCTL_DROPIN}"
  les_write_root_file "${LES_SYSCTL_DROPIN}" "$(les_sysctl_content "${profile}")"
  les_run sudo sysctl --system
}

les_sysctl_status() {
  les_section "Sysctl Status"
  les_status_line "Drop-in" "$(if [[ -r "${LES_SYSCTL_DROPIN}" ]]; then echo present; else echo absent; fi)"
}
