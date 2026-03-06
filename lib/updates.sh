#!/usr/bin/env bash
# Licensed under the Apache License, Version 2.0.

set -euo pipefail

# shellcheck source=./common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"
# shellcheck source=./package-install.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/package-install.sh"

LES_AUTO_UPGRADES_FILE="/etc/apt/apt.conf.d/20auto-upgrades"
LES_UNATTENDED_FILE="/etc/apt/apt.conf.d/52linux-extra-security-unattended-upgrades"

les_updates_plan() {
  local mode="${1:-security-auto}"
  les_section "Updates Plan"
  les_status_line "Mode" "${mode}"
  les_status_line "Auto upgrades" "Enable unattended security updates"
  les_status_line "Artifacts" "${LES_AUTO_UPGRADES_FILE}, ${LES_UNATTENDED_FILE}"
}

les_updates_apply() {
  local mode="${1:-security-auto}"
  local manifest
  local auto_content
  local unattended_content

  [[ "${mode}" == "security-auto" ]] || les_die "Unsupported update mode: ${mode}"
  les_pkg_install_group host-hardening

  manifest="$(les_new_manifest updates)"
  les_write_state_file "latest-updates-manifest" "${manifest}"
  [[ -e "${LES_AUTO_UPGRADES_FILE}" ]] && les_record_manifest_copy "${manifest}" "${LES_AUTO_UPGRADES_FILE}"
  [[ -e "${LES_UNATTENDED_FILE}" ]] && les_record_manifest_copy "${manifest}" "${LES_UNATTENDED_FILE}"

  auto_content='APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";'

  unattended_content='Unattended-Upgrade::Allowed-Origins {
  "${distro_id}:${distro_codename}";
  "${distro_id}:${distro_codename}-security";
};
Unattended-Upgrade::Automatic-Reboot "false";
Unattended-Upgrade::Remove-Unused-Dependencies "true";'

  les_write_root_file "${LES_AUTO_UPGRADES_FILE}" "${auto_content}"
  les_write_root_file "${LES_UNATTENDED_FILE}" "${unattended_content}"

  les_run sudo systemctl enable --now unattended-upgrades
}

les_updates_status() {
  les_section "Updates Status"
  les_status_line "unattended-upgrades" "$(les_service_state unattended-upgrades)"
  les_status_line "20auto-upgrades" "$(if [[ -r "${LES_AUTO_UPGRADES_FILE}" ]]; then echo present; else echo absent; fi)"
}
