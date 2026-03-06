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
  les_require_sudo

  while IFS='|' read -r source_path backup_path; do
    [[ -n "${source_path}" && -n "${backup_path}" ]] || continue
    if [[ -e "${backup_path}" ]]; then
      sudo rm -rf "${source_path}"
      sudo cp -a "${backup_path}" "${source_path}"
      les_info "Restored ${source_path}"
    fi
  done <"${manifest}"
}

les_rollback_interactive() {
  local manifest
  manifest="$(les_latest_manifest "ufw")"
  if [[ -z "${manifest}" ]]; then
    les_die "No rollback manifests were found in ${LES_STATE_ROOT}."
  fi
  les_warn "This will restore files from: ${manifest}"
  les_confirm "Continue with rollback?" || return 1
  les_restore_manifest "${manifest}"
  les_info "Rollback completed."
}
