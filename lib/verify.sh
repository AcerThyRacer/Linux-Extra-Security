#!/usr/bin/env bash
# Licensed under the Apache License, Version 2.0.

set -euo pipefail

# shellcheck source=./common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"
# shellcheck source=./dns.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/dns.sh"
# shellcheck source=./ufw.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/ufw.sh"
# shellcheck source=./network-report.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/network-report.sh"
# shellcheck source=./system-audit.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/system-audit.sh"

les_verify_basic_web() {
  if curl -fsSL https://example.com >/dev/null 2>&1; then
    printf 'pass\n'
  else
    printf 'fail\n'
  fi
}

les_verify_plain_dns_block() {
  if les_command_exists dig; then
    if dig @1.1.1.1 google.com +time=2 +tries=1 >/dev/null 2>&1; then
      printf 'fail\n'
    else
      printf 'pass\n'
    fi
  else
    printf 'skipped\n'
  fi
}

les_verify_nextdns() {
  if les_command_exists curl && [[ -r /etc/nextdns.conf ]]; then
    curl -fsSL https://test.nextdns.io 2>/dev/null | python3 - <<'PY'
import json
import sys

try:
    payload = json.load(sys.stdin)
    print(payload.get("status", "unknown"))
except Exception:
    print("unavailable")
PY
  else
    printf 'not-configured\n'
  fi
}

les_verify_malware_block() {
  if les_command_exists dig; then
    dig malware.wicar.org +short 2>/dev/null || true
  fi
}

les_verify_rollback_inventory() {
  if [[ -d "${LES_STATE_ROOT}" ]] && ls "${LES_STATE_ROOT}"/*.manifest >/dev/null 2>&1; then
    printf 'pass\n'
  else
    printf 'fail\n'
  fi
}

les_verify_package_manager() {
  if sudo apt-get update -qq >/dev/null 2>&1; then
    printf 'pass\n'
  else
    printf 'fail\n'
  fi
}

les_verify_service_exposure() {
  ss -lntup 2>/dev/null | awk 'NR==1 || NR<=12 {print}'
}

les_verify_score() {
  local web_result="$1"
  local dns_result="$2"
  local rollback_result="$3"
  local apt_result="$4"
  local score=0

  [[ "${web_result}" == "pass" ]] && score=$((score + 25))
  [[ "${dns_result}" == "pass" ]] && score=$((score + 25))
  [[ "${rollback_result}" == "pass" ]] && score=$((score + 25))
  [[ "${apt_result}" == "pass" ]] && score=$((score + 25))
  printf '%s\n' "${score}"
}

les_verify_human_report() {
  local web_result
  local dns_result
  local rollback_result
  local apt_result
  local nextdns_result
  local score

  web_result="$(les_verify_basic_web)"
  dns_result="$(les_verify_plain_dns_block)"
  rollback_result="$(les_verify_rollback_inventory)"
  apt_result="$(les_verify_package_manager)"
  nextdns_result="$(les_verify_nextdns)"
  score="$(les_verify_score "${web_result}" "${dns_result}" "${rollback_result}" "${apt_result}")"

  les_section "Verification Summary"
  les_status_line "HTTPS egress" "${web_result}"
  les_status_line "Plain DNS block" "${dns_result}"
  les_status_line "Rollback inventory" "${rollback_result}"
  les_status_line "APT reachability" "${apt_result}"
  les_status_line "NextDNS status" "${nextdns_result}"
  les_status_line "Verification score" "${score}/100"

  les_network_report_human
  les_system_audit_report
  les_dns_browser_bypass_hints

  les_section "Service Exposure"
  les_verify_service_exposure
}

les_verify_json_report() {
  local output_path="${1:-${LES_REPORT_ROOT}/verification-$(les_timestamp).json}"
  local web_result dns_result rollback_result apt_result nextdns_result score

  les_ensure_runtime
  web_result="$(les_verify_basic_web)"
  dns_result="$(les_verify_plain_dns_block)"
  rollback_result="$(les_verify_rollback_inventory)"
  apt_result="$(les_verify_package_manager)"
  nextdns_result="$(les_verify_nextdns)"
  score="$(les_verify_score "${web_result}" "${dns_result}" "${rollback_result}" "${apt_result}")"

  python3 - "${output_path}" "${web_result}" "${dns_result}" "${rollback_result}" "${apt_result}" "${nextdns_result}" "${score}" <<'PY'
import json
import sys

path, web, dns, rollback, apt, nextdns, score = sys.argv[1:]
data = {
    "checks": {
        "httpsEgress": web,
        "plaintextDnsBlocked": dns,
        "rollbackInventory": rollback,
        "aptReachability": apt,
        "nextdnsStatus": nextdns,
    },
    "summary": {
        "score": int(score),
    },
}
with open(path, "w", encoding="utf-8") as handle:
    json.dump(data, handle, indent=2)
    handle.write("\n")
print(path)
PY
}

les_verify_all() {
  local text_report
  local json_report

  text_report="${LES_REPORT_ROOT}/verification-$(les_timestamp).txt"
  les_ensure_runtime
  les_verify_human_report | tee "${text_report}"
  json_report="$(les_verify_json_report)"
  les_info "Wrote text report to ${text_report}"
  les_info "Wrote JSON report to ${json_report}"
}
