#!/usr/bin/env bash
# Licensed under the Apache License, Version 2.0.

set -euo pipefail

# shellcheck source=./common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

LES_APT_UPDATED="${LES_APT_UPDATED:-0}"

les_pkg_is_installed() {
  dpkg -s "$1" >/dev/null 2>&1
}

les_pkg_update_once() {
  les_require_debian_family
  les_require_sudo
  if [[ "${LES_APT_UPDATED}" != "1" ]]; then
    les_run sudo apt-get update
    LES_APT_UPDATED="1"
  fi
}

les_pkg_install_if_missing() {
  local to_install=()
  local package_name

  les_require_debian_family
  for package_name in "$@"; do
    if ! les_pkg_is_installed "${package_name}"; then
      to_install+=("${package_name}")
    fi
  done

  if ((${#to_install[@]} == 0)); then
    les_info "Requested packages are already installed."
    return 0
  fi

  les_pkg_update_once
  les_run sudo apt-get install -y "${to_install[@]}"
}

les_pkg_install_group() {
  local group_name="$1"

  case "${group_name}" in
    base)
      les_pkg_install_if_missing curl ca-certificates jq dnsutils ufw
      ;;
    host-hardening)
      les_pkg_install_if_missing apparmor apparmor-utils fail2ban unattended-upgrades apt-listchanges
      ;;
    audit)
      les_pkg_install_if_missing iproute2 procps net-tools
      ;;
    *)
      les_die "Unknown package group: ${group_name}"
      ;;
  esac
}
