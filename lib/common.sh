#!/usr/bin/env bash
# Licensed under the Apache License, Version 2.0.

set -euo pipefail

LES_VERSION="2.0.0"
LES_COMMON_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LES_REPO_ROOT="$(cd "${LES_COMMON_DIR}/.." && pwd)"
LES_RUNTIME_DIR="${LES_RUNTIME_DIR:-${LES_REPO_ROOT}/.runtime}"
LES_BACKUP_ROOT="${LES_BACKUP_ROOT:-${LES_RUNTIME_DIR}/backups}"
LES_STATE_ROOT="${LES_STATE_ROOT:-${LES_RUNTIME_DIR}/state}"
LES_REPORT_ROOT="${LES_REPORT_ROOT:-${LES_RUNTIME_DIR}/reports}"
LES_PROFILE_ROOT="${LES_PROFILE_ROOT:-${LES_REPO_ROOT}/profiles}"
LES_DRY_RUN="${LES_DRY_RUN:-0}"
LES_ASSUME_YES="${LES_ASSUME_YES:-0}"
LES_ACTIVE_PROFILE="${LES_ACTIVE_PROFILE:-}"

les_timestamp() {
  date +"%Y%m%d-%H%M%S"
}

les_ensure_runtime() {
  mkdir -p "${LES_BACKUP_ROOT}" "${LES_STATE_ROOT}" "${LES_REPORT_ROOT}"
}

les_info() {
  printf '[INFO] %s\n' "$*"
}

les_note() {
  printf '[NOTE] %s\n' "$*"
}

les_warn() {
  printf '[WARN] %s\n' "$*" >&2
}

les_error() {
  printf '[ERROR] %s\n' "$*" >&2
}

les_die() {
  les_error "$*"
  exit 1
}

les_section() {
  printf '\n## %s\n' "$*"
}

les_subsection() {
  printf '\n### %s\n' "$*"
}

les_status_line() {
  printf '%-24s %s\n' "$1" "$2"
}

les_command_exists() {
  command -v "$1" >/dev/null 2>&1
}

les_require_commands() {
  local missing=()
  local cmd
  for cmd in "$@"; do
    if ! les_command_exists "${cmd}"; then
      missing+=("${cmd}")
    fi
  done
  if ((${#missing[@]} > 0)); then
    les_die "Missing required command(s): ${missing[*]}"
  fi
}

les_require_sudo() {
  if les_is_dry_run; then
    return 0
  fi
  if ! sudo -n true >/dev/null 2>&1; then
    les_info "Sudo access is required for this action."
    sudo -v
  fi
}

les_is_dry_run() {
  [[ "${LES_DRY_RUN}" == "1" ]]
}

les_run() {
  if les_is_dry_run; then
    printf '[DRY-RUN] '
    printf '%q ' "$@"
    printf '\n'
    return 0
  fi
  "$@"
}

les_confirm() {
  local prompt="${1:-Continue?}"
  local reply

  if [[ "${LES_ASSUME_YES}" == "1" ]]; then
    les_info "Auto-confirm enabled: ${prompt}"
    return 0
  fi

  read -r -p "${prompt} [y/N]: " reply
  [[ "${reply,,}" == "y" || "${reply,,}" == "yes" ]]
}

les_prompt() {
  local prompt="$1"
  local default_value="${2:-}"
  local reply

  if [[ -n "${default_value}" ]]; then
    read -r -p "${prompt} [${default_value}]: " reply
    printf '%s\n' "${reply:-${default_value}}"
  else
    read -r -p "${prompt}: " reply
    printf '%s\n' "${reply}"
  fi
}

les_choose_from_menu() {
  local prompt="$1"
  shift
  local options=("$@")
  local index=1
  local choice

  printf '%s\n' "${prompt}"
  for choice in "${options[@]}"; do
    printf '  %d. %s\n' "${index}" "${choice}"
    index=$((index + 1))
  done

  while true; do
    read -r -p "Select an option [1-${#options[@]}]: " choice
    if [[ "${choice}" =~ ^[0-9]+$ ]] && ((choice >= 1 && choice <= ${#options[@]})); then
      printf '%s\n' "${options[$((choice - 1))]}"
      return 0
    fi
    les_warn "Invalid choice."
  done
}

les_detect_os() {
  if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    source /etc/os-release
    printf '%s:%s\n' "${ID:-unknown}" "${VERSION_ID:-unknown}"
  else
    printf 'unknown:unknown\n'
  fi
}

les_require_debian_family() {
  local os_id
  os_id="$(les_detect_os | cut -d: -f1)"
  case "${os_id}" in
    debian|ubuntu|zorin)
      return 0
      ;;
    *)
      les_die "This toolkit currently targets Debian-based systems. Detected: ${os_id}"
      ;;
  esac
}

les_backup_path() {
  local path="$1"
  local safe_name

  les_ensure_runtime
  safe_name="$(printf '%s' "${path}" | sed 's#/#_#g' | sed 's#^_##')"
  printf '%s/%s-%s\n' "${LES_BACKUP_ROOT}" "$(les_timestamp)" "${safe_name}"
}

les_backup_file() {
  local path="$1"
  local destination

  [[ -e "${path}" ]] || return 0
  destination="$(les_backup_path "${path}")"
  les_run sudo cp -a "${path}" "${destination}"
  les_info "Backed up ${path} to ${destination}"
}

les_write_state_file() {
  local name="$1"
  shift
  les_ensure_runtime
  printf '%s\n' "$*" >"${LES_STATE_ROOT}/${name}"
}

les_read_state_file() {
  local name="$1"
  [[ -r "${LES_STATE_ROOT}/${name}" ]] && cat "${LES_STATE_ROOT}/${name}"
}

les_new_manifest() {
  local module="$1"
  local manifest="${LES_STATE_ROOT}/${module}-$(les_timestamp).manifest"
  les_ensure_runtime
  : >"${manifest}"
  printf '%s\n' "${manifest}"
}

les_append_manifest_entry() {
  local manifest="$1"
  local source_path="$2"
  local backup_path="$3"
  mkdir -p "$(dirname "${manifest}")"
  printf '%s|%s\n' "${source_path}" "${backup_path}" >>"${manifest}"
}

les_latest_manifest() {
  local prefix="$1"
  ls -1t "${LES_STATE_ROOT}"/"${prefix}"-*.manifest 2>/dev/null | head -n 1 || true
}

les_list_manifests() {
  ls -1t "${LES_STATE_ROOT}"/*.manifest 2>/dev/null || true
}

les_record_manifest_copy() {
  local manifest="$1"
  local source_path="$2"
  local backup_path

  backup_path="$(les_backup_path "${source_path}")"
  les_run sudo cp -a "${source_path}" "${backup_path}"
  les_append_manifest_entry "${manifest}" "${source_path}" "${backup_path}"
}

les_profile_path() {
  local profile_name="$1"
  printf '%s/%s.env\n' "${LES_PROFILE_ROOT}" "${profile_name}"
}

les_load_profile() {
  local profile_name="$1"
  local profile_path

  profile_path="$(les_profile_path "${profile_name}")"
  [[ -r "${profile_path}" ]] || les_die "Profile not found: ${profile_name}"

  LES_ACTIVE_PROFILE="${profile_name}"
  # shellcheck disable=SC1090
  source "${profile_path}"
}

les_detect_vpn() {
  if les_command_exists nmcli; then
    nmcli -t -f NAME,TYPE connection show --active 2>/dev/null | awk -F: '$2 ~ /(vpn|wireguard)/ {print $1}'
  fi
}

les_service_state() {
  local service_name="$1"
  if systemctl is-active --quiet "${service_name}" 2>/dev/null; then
    printf 'active\n'
  elif systemctl list-unit-files "${service_name}.service" --no-legend 2>/dev/null | grep -q .; then
    printf 'inactive\n'
  else
    printf 'not-installed\n'
  fi
}

les_write_report() {
  local report_name="$1"
  shift
  les_ensure_runtime
  printf '%s\n' "$*" >"${LES_REPORT_ROOT}/${report_name}"
  printf '%s\n' "${LES_REPORT_ROOT}/${report_name}"
}

les_write_root_file() {
  local target_path="$1"
  local content="$2"

  if les_is_dry_run; then
    les_info "Would write ${target_path}"
    printf '%s\n' "${content}"
    return 0
  fi

  les_require_sudo
  sudo mkdir -p "$(dirname "${target_path}")"
  printf '%s\n' "${content}" | sudo tee "${target_path}" >/dev/null
}
