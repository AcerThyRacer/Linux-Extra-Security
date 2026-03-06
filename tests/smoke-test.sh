#!/usr/bin/env bash
# Licensed under the Apache License, Version 2.0.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

check_no_machine_specific_content() {
  if grep -R --line-number --exclude-dir=.git --exclude-dir=.runtime -E '^profile [a-z0-9]{6,}$' "${ROOT_DIR}" >/dev/null 2>&1; then
    echo "Found a concrete NextDNS profile ID in repository content." >&2
    return 1
  fi

  if grep -R --line-number --exclude-dir=.git --exclude-dir=.runtime -E '[d]eviceID|[d]eviceName|[s]rcIP|[d]estIP' "${ROOT_DIR}" >/dev/null 2>&1; then
    echo "Found provider response metadata in repository content." >&2
    return 1
  fi

  if grep -R --line-number --exclude-dir=.git --exclude-dir=.runtime -E '[p]roton[0-9]*|[w]g[0-9]+|[t]un[0-9]+' "${ROOT_DIR}" >/dev/null 2>&1; then
    echo "Found a likely machine-specific VPN interface reference in repository content." >&2
    return 1
  fi
}

check_shell_syntax() {
  local script
  while IFS= read -r script; do
    bash -n "${script}"
  done < <(find "${ROOT_DIR}/bin" "${ROOT_DIR}/lib" "${ROOT_DIR}/tests" -type f -name '*.sh' | sort)
}

check_required_files() {
  local required=(
    "${ROOT_DIR}/README.md"
    "${ROOT_DIR}/bin/linux-extra-security"
    "${ROOT_DIR}/lib/common.sh"
    "${ROOT_DIR}/lib/dns.sh"
    "${ROOT_DIR}/lib/portmaster.sh"
    "${ROOT_DIR}/lib/ufw.sh"
    "${ROOT_DIR}/lib/verify.sh"
    "${ROOT_DIR}/lib/rollback.sh"
  )
  local file
  for file in "${required[@]}"; do
    [[ -f "${file}" ]] || {
      echo "Missing required file: ${file}" >&2
      return 1
    }
  done
}

check_required_files
check_shell_syntax
check_no_machine_specific_content

echo "Smoke test passed."
