#!/usr/bin/env bash
# Licensed under the Apache License, Version 2.0.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

required_keys=(
  PROFILE_NAME
  PROFILE_DESCRIPTION
  DNS_PROVIDER
  PORTMASTER_PRESET
  UFW_PROFILE
  TELEMETRY_LEVEL
  SSH_HARDEN_MODE
  UPDATES_MODE
  APPARMOR_MODE
  FAIL2BAN_MODE
  SERVICES_PROFILE
  JOURNALD_PROFILE
  SYSCTL_PROFILE
  BROWSER_PROFILE
)

while IFS= read -r profile; do
  unset PROFILE_NAME PROFILE_DESCRIPTION DNS_PROVIDER PORTMASTER_PRESET UFW_PROFILE
  unset TELEMETRY_LEVEL SSH_HARDEN_MODE UPDATES_MODE APPARMOR_MODE FAIL2BAN_MODE
  unset SERVICES_PROFILE JOURNALD_PROFILE SYSCTL_PROFILE BROWSER_PROFILE
  # shellcheck disable=SC1090
  source "${profile}"

  for key in "${required_keys[@]}"; do
    [[ -n "${!key:-}" ]] || {
      echo "Missing ${key} in ${profile}" >&2
      exit 1
    }
  done
done < <(find "${ROOT_DIR}/profiles" -type f -name '*.env' | sort)

echo "Profile test passed."
