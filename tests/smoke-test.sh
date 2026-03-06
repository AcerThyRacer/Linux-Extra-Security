#!/usr/bin/env bash
# Licensed under the Apache License, Version 2.0.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

check_no_machine_specific_content() {
  python3 - "${ROOT_DIR}" <<'PY'
import pathlib
import re
import sys

root = pathlib.Path(sys.argv[1])
banned_exact = ["674" + "49d"]
patterns = [
    re.compile(r"^profile [a-z0-9]{6,}$", re.MULTILINE),
    re.compile(r"deviceID|deviceName|srcIP|destIP"),
    re.compile(r"\b(proton[0-9]*|wg[0-9]+|tun[0-9]+)\b"),
]

for path in root.rglob("*"):
    if not path.is_file():
        continue
    if any(part in {".git", ".runtime"} for part in path.parts):
        continue
    if path.name == "smoke-test.sh":
        continue
    try:
      content = path.read_text(encoding="utf-8")
    except Exception:
      continue
    for token in banned_exact:
        if token in content:
            print(f"Found banned token in repository: {path}", file=sys.stderr)
            raise SystemExit(1)
    for pattern in patterns:
        if pattern.search(content):
            print(f"Found machine-specific content in repository: {path}", file=sys.stderr)
            raise SystemExit(1)
PY
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
    "${ROOT_DIR}/lib/package-install.sh"
    "${ROOT_DIR}/lib/system-audit.sh"
    "${ROOT_DIR}/lib/network-report.sh"
    "${ROOT_DIR}/lib/telemetry.sh"
    "${ROOT_DIR}/lib/ssh.sh"
    "${ROOT_DIR}/lib/updates.sh"
    "${ROOT_DIR}/lib/apparmor.sh"
    "${ROOT_DIR}/lib/fail2ban.sh"
    "${ROOT_DIR}/lib/services.sh"
    "${ROOT_DIR}/lib/journald.sh"
    "${ROOT_DIR}/lib/sysctl.sh"
    "${ROOT_DIR}/lib/browser.sh"
    "${ROOT_DIR}/profiles/balanced-desktop.env"
    "${ROOT_DIR}/profiles/privacy-max.env"
    "${ROOT_DIR}/profiles/vpn-friendly.env"
    "${ROOT_DIR}/profiles/workstation-safe.env"
    "${ROOT_DIR}/docs/guided-flows.md"
    "${ROOT_DIR}/docs/profiles.md"
    "${ROOT_DIR}/docs/debian-compatibility.md"
    "${ROOT_DIR}/docs/module-reference.md"
    "${ROOT_DIR}/docs/reporting.md"
    "${ROOT_DIR}/docs/troubleshooting.md"
  )
  local file
  for file in "${required[@]}"; do
    [[ -f "${file}" ]] || {
      echo "Missing required file: ${file}" >&2
      return 1
    }
  done
}

check_reports_gitignored() {
  grep -q '^\.runtime/$' "${ROOT_DIR}/.gitignore"
}

check_required_files
check_shell_syntax
check_no_machine_specific_content
check_reports_gitignored

echo "Smoke test passed."
