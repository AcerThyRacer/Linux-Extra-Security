#!/usr/bin/env bash
# Licensed under the Apache License, Version 2.0.

set -euo pipefail

# shellcheck source=./common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

les_verify_basic_web() {
  les_info "Checking HTTPS connectivity"
  curl -fsSL https://example.com >/dev/null
}

les_verify_plain_dns_block() {
  les_info "Checking whether direct plaintext DNS is blocked"
  if les_command_exists dig; then
    if dig @1.1.1.1 google.com +time=2 +tries=1 >/dev/null 2>&1; then
      les_warn "Direct plaintext DNS appears reachable."
      return 1
    fi
    les_info "Direct plaintext DNS looks blocked."
  else
    les_warn "Skipping direct DNS test because dig is not installed."
  fi
}

les_verify_nextdns() {
  if ! les_command_exists curl; then
    return 0
  fi
  if [[ -r /etc/nextdns.conf ]]; then
    les_info "Checking NextDNS status endpoint"
    curl -fsSL https://test.nextdns.io
  fi
}

les_verify_malware_block() {
  les_info "Checking malware.wicar.org resolution"
  if les_command_exists dig; then
    dig malware.wicar.org +short || true
  fi
}

les_verify_backups() {
  les_info "Checking runtime backup state"
  [[ -d "${LES_BACKUP_ROOT}" ]] || les_die "Backup directory not found: ${LES_BACKUP_ROOT}"
  find "${LES_BACKUP_ROOT}" -maxdepth 1 -type f | head -n 5 || true
}

les_verify_package_manager() {
  les_info "Checking package manager reachability"
  sudo apt-get update >/dev/null
}

les_verify_all() {
  les_verify_basic_web
  les_verify_plain_dns_block || true
  les_verify_nextdns || true
  les_verify_malware_block || true
  les_verify_backups
  les_verify_package_manager
  les_info "Verification completed."
}
