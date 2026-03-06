#!/usr/bin/env bash
# Licensed under the Apache License, Version 2.0.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${ROOT_DIR}/lib/common.sh"

# Mock les_timestamp
les_timestamp() {
  echo "20231027-120000"
}

# Mock les_ensure_runtime to do nothing
les_ensure_runtime() {
  :
}

# Override LES_BACKUP_ROOT for testing
LES_BACKUP_ROOT="/tmp/les_backups"

test_les_backup_path() {
  local input_path="$1"
  local expected_output="$2"
  local actual_output

  actual_output=$(les_backup_path "${input_path}")

  if [[ "${actual_output}" == "${expected_output}" ]]; then
    echo "PASS: les_backup_path '${input_path}' -> '${actual_output}'"
  else
    echo "FAIL: les_backup_path '${input_path}'"
    echo "  Expected: ${expected_output}"
    echo "  Actual:   ${actual_output}"
    exit 1
  fi
}

echo "Running les_backup_path tests..."

test_les_backup_path "/etc/ufw" "/tmp/les_backups/20231027-120000-etc_ufw"
test_les_backup_path "/tmp/foo/bar" "/tmp/les_backups/20231027-120000-tmp_foo_bar"
test_les_backup_path "/" "/tmp/les_backups/20231027-120000-"
test_les_backup_path "relative/path" "/tmp/les_backups/20231027-120000-relative_path"
test_les_backup_path "/leading_slash" "/tmp/les_backups/20231027-120000-leading_slash"

echo "All les_backup_path tests passed!"
