#!/usr/bin/env bash
# Licensed under the Apache License, Version 2.0.

set -euo pipefail

# shellcheck source=./common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

LES_TELEMETRY_ENV_FILE="/etc/default/popularity-contest"
LES_APPORT_FILE="/etc/default/apport"

les_telemetry_plan() {
  local level="${1:-balanced}"

  les_section "Telemetry Plan"
  les_status_line "Profile" "${level}"
  case "${level}" in
    lite)
      les_status_line "Services" "Disable whoopsie when present (leave geoclue)"
      les_status_line "Package telemetry" "Turn off popularity-contest when present"
      ;;
    balanced)
      les_status_line "Services" "Disable whoopsie and geoclue when present"
      les_status_line "Package telemetry" "Turn off popularity-contest when present"
      ;;
    strict)
      les_status_line "Services" "Disable whoopsie, geoclue, avahi-daemon, cups-browsed when present"
      les_status_line "Package telemetry" "Turn off popularity-contest and apport when present"
      ;;
    *)
      les_die "Unknown telemetry level: ${level}"
      ;;
  esac
}

les_telemetry_set_key_value() {
  local file_path="$1"
  local key="$2"
  local value="$3"
  local manifest="$4"
  local temp_file

  temp_file="$(mktemp)"
  if [[ -f "${file_path}" ]]; then
    les_record_manifest_copy "${manifest}" "${file_path}"
    awk -v key="${key}" -v value="${value}" '
      BEGIN { done=0 }
      $0 ~ "^" key "=" {
        print key "=" value
        done=1
        next
      }
      { print }
      END {
        if (!done) {
          print key "=" value
        }
      }
    ' "${file_path}" >"${temp_file}"
  else
    printf '%s=%s\n' "${key}" "${value}" >"${temp_file}"
  fi

  if les_is_dry_run; then
    les_info "Would update ${file_path}"
    cat "${temp_file}"
  else
    les_require_sudo
    sudo mkdir -p "$(dirname "${file_path}")"
    sudo cp "${temp_file}" "${file_path}"
  fi
  rm -f "${temp_file}"
}

les_telemetry_apply() {
  local level="${1:-}"

  if [[ -z "${level}" ]]; then
    level="$(les_choose_from_menu "Select Telemetry Reduction Level:" \
      "lite" \
      "balanced" \
      "strict")"
  fi

  les_telemetry_plan "${level}"
  les_confirm "Apply telemetry reduction?" || return 0

  local manifest
  local services=("whoopsie")

  case "${level}" in
    lite) ;;
    balanced)
      services+=("geoclue")
      ;;
    strict)
      services+=("geoclue" "avahi-daemon" "cups-browsed")
      ;;
    *)
      les_die "Unknown telemetry level: ${level}"
      ;;
  esac

  manifest="$(les_new_manifest telemetry)"
  les_write_state_file "latest-telemetry-manifest" "${manifest}"
  les_telemetry_set_key_value "${LES_TELEMETRY_ENV_FILE}" POPULARITY_CONTEST no "${manifest}"
  les_telemetry_set_key_value "${LES_APPORT_FILE}" enabled 0 "${manifest}"

  for service_name in "${services[@]}"; do
    if systemctl list-unit-files 2>/dev/null | grep -q "^${service_name}\.service"; then
      les_run sudo systemctl disable --now "${service_name}.service"
    fi
  done

  les_info "Applied telemetry profile: ${level}"
}

les_telemetry_status() {
  les_section "Telemetry Status"
  les_status_line "whoopsie" "$(les_service_state whoopsie)"
  les_status_line "geoclue" "$(les_service_state geoclue)"
  les_status_line "avahi-daemon" "$(les_service_state avahi-daemon)"
  les_status_line "cups-browsed" "$(les_service_state cups-browsed)"
  if [[ -r "${LES_TELEMETRY_ENV_FILE}" ]]; then
    les_status_line "popularity-contest" "$(awk -F= '/POPULARITY_CONTEST/ {print $2; exit}' "${LES_TELEMETRY_ENV_FILE}")"
  fi
  if [[ -r "${LES_APPORT_FILE}" ]]; then
    les_status_line "apport" "$(awk -F= '/enabled/ {print $2; exit}' "${LES_APPORT_FILE}")"
  fi
}
