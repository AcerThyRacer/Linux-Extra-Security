#!/usr/bin/env bash
# Licensed under the Apache License, Version 2.0.

set -euo pipefail

# shellcheck source=./common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

LES_JOURNALD_DROPIN="/etc/systemd/journald.conf.d/99-linux-extra-security.conf"

les_journald_plan() {
  local profile="${1:-balanced}"
  les_section "Journald Plan"
  les_status_line "Profile" "${profile}"
  les_status_line "Drop-in" "${LES_JOURNALD_DROPIN}"
}

les_journald_content() {
  case "${1:-balanced}" in
    balanced)
      cat <<'EOF'
[Journal]
Compress=yes
Storage=auto
SystemMaxUse=200M
MaxRetentionSec=2week
ForwardToSyslog=no
EOF
      ;;
    private)
      cat <<'EOF'
[Journal]
Compress=yes
Storage=persistent
SystemMaxUse=100M
MaxRetentionSec=7day
ForwardToSyslog=no
Seal=yes
EOF
      ;;
    *)
      les_die "Unknown journald profile: $1"
      ;;
  esac
}

les_journald_apply() {
  local profile="${1:-balanced}"
  local manifest

  manifest="$(les_new_manifest journald)"
  les_write_state_file "latest-journald-manifest" "${manifest}"
  [[ -e "${LES_JOURNALD_DROPIN}" ]] && les_record_manifest_copy "${manifest}" "${LES_JOURNALD_DROPIN}"
  les_write_root_file "${LES_JOURNALD_DROPIN}" "$(les_journald_content "${profile}")"
  les_run sudo systemctl restart systemd-journald
}

les_journald_status() {
  les_section "Journald Status"
  les_status_line "Drop-in" "$(if [[ -r "${LES_JOURNALD_DROPIN}" ]]; then echo present; else echo absent; fi)"
}
