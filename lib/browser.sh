#!/usr/bin/env bash
# Licensed under the Apache License, Version 2.0.

set -euo pipefail

# shellcheck source=./common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

LES_FIREFOX_POLICY="/etc/firefox/policies/policies.json"

les_browser_plan() {
  local profile="${1:-privacy-baseline}"
  les_section "Browser Plan"
  les_status_line "Profile" "${profile}"
  les_status_line "Firefox policy" "Disable browser-level DoH override when managed"
  les_status_line "Chromium guidance" "Print secure DNS and telemetry alignment reminders"
}

les_browser_firefox_policy_content() {
  cat <<'EOF'
{
  "policies": {
    "DisableFirefoxStudies": true,
    "DisableTelemetry": true,
    "DNSOverHTTPS": {
      "Enabled": false,
      "Locked": true
    }
  }
}
EOF
}

les_browser_apply() {
  local profile="${1:-}"
  local manifest

  if [[ -z "${profile}" ]]; then
    profile="$(les_choose_from_menu "Select Browser Profile:" \
      "privacy-baseline" \
      "maximum-privacy" \
      "developer-safe")"
  fi

  les_browser_plan "${profile}"
  les_confirm "Apply browser profile?" || return 0

  case "${profile}" in
    privacy-baseline|maximum-privacy|developer-safe) ;;
    *)
      les_die "Unknown browser profile: ${profile}"
      ;;
  esac

  manifest="$(les_new_manifest browser)"
  les_write_state_file "latest-browser-manifest" "${manifest}"
  [[ -e "${LES_FIREFOX_POLICY}" ]] && les_record_manifest_copy "${manifest}" "${LES_FIREFOX_POLICY}"
  les_write_root_file "${LES_FIREFOX_POLICY}" "$(les_browser_firefox_policy_content)"
  les_info "Review Chromium/Chrome/Brave secure DNS settings and point them to the OS resolver."
}

les_browser_status() {
  les_section "Browser Status"
  les_status_line "Firefox policy" "$(if [[ -r "${LES_FIREFOX_POLICY}" ]]; then echo present; else echo absent; fi)"
  les_note "Chromium-family browsers should keep Secure DNS disabled or set to system resolver mode."
}
