#!/usr/bin/env bash
# Licensed under the Apache License, Version 2.0.

set -euo pipefail

# shellcheck source=./common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

les_restore_manifest() {
  local manifest="$1"
  local source_path
  local backup_path

  [[ -r "${manifest}" ]] || les_die "Rollback manifest not found: ${manifest}"
  while IFS='|' read -r source_path backup_path; do
    [[ -n "${source_path}" && -n "${backup_path}" ]] || continue
    if [[ -e "${backup_path}" ]]; then
      if les_is_dry_run; then
        les_info "Would restore ${source_path} from ${backup_path}"
      else
        les_require_sudo
        sudo rm -rf "${source_path}"
        sudo cp -a "${backup_path}" "${source_path}"
        les_info "Restored ${source_path}"
      fi
    fi
  done <"${manifest}"
}

les_rollback_list_points() {
  les_section "Rollback Points"
  if ! ls "${LES_STATE_ROOT}"/*.manifest >/dev/null 2>&1; then
    les_warn "No rollback manifests found."
    return 0
  fi
  ls -1t "${LES_STATE_ROOT}"/*.manifest
}

les_rollback_preview() {
  local manifest="$1"
  les_section "Rollback Preview"
  [[ -r "${manifest}" ]] || les_die "Rollback manifest not found: ${manifest}"
  awk -F'|' '{print "  restore " $1 " <- " $2}' "${manifest}"
}

les_rollback_latest_for_module() {
  local module="$1"
  les_latest_manifest "${module}"
}

les_rollback_restore_module() {
  local module="$1"
  local manifest

  manifest="$(les_rollback_latest_for_module "${module}")"
  [[ -n "${manifest}" ]] || les_die "No rollback manifest found for module: ${module}"
  les_rollback_preview "${manifest}"
  les_confirm "Restore the latest ${module} rollback point?" || return 1
  les_restore_manifest "${manifest}"
}

les_rollback_interactive() {
  local manifest choice
  choice="$(les_choose_from_menu "Rollback target" "latest-run" "dns" "portmaster" "ufw" "telemetry" "ssh" "updates" "journald" "sysctl" "browser" "fail2ban")"
  if [[ "${choice}" == "latest-run" ]]; then
    manifest="$(ls -1t "${LES_STATE_ROOT}"/*.manifest 2>/dev/null | head -n 1 || true)"
  else
    manifest="$(les_latest_manifest "${choice}")"
  fi
  if [[ -z "${manifest}" ]]; then
    les_die "No rollback manifests were found in ${LES_STATE_ROOT}."
  fi
  les_rollback_preview "${manifest}"
  les_confirm "Continue with rollback?" || return 1
  les_restore_manifest "${manifest}"
  les_info "Rollback completed."
}
