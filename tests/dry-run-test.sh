#!/usr/bin/env bash
# Licensed under the Apache License, Version 2.0.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

run_and_assert() {
  local description="$1"
  shift
  local output

  output="$("$@" 2>&1)"
  printf '%s\n' "${output}" | grep -q "\[DRY-RUN\]\|\[INFO\]\|##"
  printf 'checked: %s\n' "${description}"
}

run_and_assert "profile apply dry run" \
  "${ROOT_DIR}/bin/linux-extra-security" --dry-run --yes profile apply balanced-desktop

run_and_assert "guided workflow dry run" \
  "${ROOT_DIR}/bin/linux-extra-security" --dry-run --yes guided desktop-hardening

run_and_assert "firewall plan" \
  "${ROOT_DIR}/bin/linux-extra-security" firewall plan locked-down

echo "Dry-run test passed."
