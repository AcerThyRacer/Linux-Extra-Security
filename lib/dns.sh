#!/usr/bin/env bash
# Licensed under the Apache License, Version 2.0.

set -euo pipefail

# shellcheck source=./common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

LES_RESOLVED_DROPIN_DIR="/etc/systemd/resolved.conf.d"
LES_RESOLVED_DROPIN_FILE="${LES_RESOLVED_DROPIN_DIR}/99-linux-extra-security.conf"
LES_NEXTDNS_CONFIG="/etc/nextdns.conf"

les_dns_provider_menu() {
  les_choose_from_menu "Choose a DNS provider" \
    "NextDNS" \
    "Quad9" \
    "AdGuard" \
    "Cloudflare" \
    "Custom"
}

les_dns_install_nextdns() {
  les_require_sudo
  if les_command_exists nextdns; then
    les_info "NextDNS CLI is already installed."
    return 0
  fi

  les_info "Installing NextDNS CLI from the official Debian repository."
  sudo wget -qO /usr/share/keyrings/nextdns.gpg https://repo.nextdns.io/nextdns.gpg
  printf 'deb [signed-by=/usr/share/keyrings/nextdns.gpg] https://repo.nextdns.io/deb stable main\n' |
    sudo tee /etc/apt/sources.list.d/nextdns.list >/dev/null
  sudo apt-get update
  sudo apt-get install -y nextdns
}

les_dns_write_resolved_dropin() {
  local dns_servers="$1"
  local dot_mode="$2"

  les_require_sudo
  les_backup_file "${LES_RESOLVED_DROPIN_FILE}"
  sudo mkdir -p "${LES_RESOLVED_DROPIN_DIR}"
  sudo tee "${LES_RESOLVED_DROPIN_FILE}" >/dev/null <<EOF
[Resolve]
DNS=${dns_servers}
FallbackDNS=
DNSOverTLS=${dot_mode}
DNSSEC=no
LLMNR=no
MulticastDNS=no
EOF
  sudo systemctl restart systemd-resolved
  les_info "Wrote ${LES_RESOLVED_DROPIN_FILE}"
}

les_dns_disable_resolved_dropin() {
  les_require_sudo
  if [[ -e "${LES_RESOLVED_DROPIN_FILE}" ]]; then
    les_backup_file "${LES_RESOLVED_DROPIN_FILE}"
    sudo rm -f "${LES_RESOLVED_DROPIN_FILE}"
    sudo systemctl restart systemd-resolved
  fi
}

les_dns_configure_nextdns() {
  local profile_id="$1"
  local mode="$2"
  local listen_port="$3"

  les_dns_install_nextdns
  les_require_sudo
  les_backup_file "${LES_NEXTDNS_CONFIG}"

  sudo nextdns stop >/dev/null 2>&1 || true
  sudo nextdns deactivate >/dev/null 2>&1 || true

  if [[ "${mode}" == "local-forwarder" ]]; then
    sudo nextdns config set -profile="${profile_id}" -report-client-info=true -cache-size=10MB \
      -listen="127.0.0.1:${listen_port}" -auto-activate=false
    les_dns_disable_resolved_dropin
    les_info "Configured NextDNS in localhost forwarder mode on 127.0.0.1:${listen_port}."
    les_info "Use Portmaster localhost-forwarder mode to send DNS to this listener."
  else
    sudo nextdns config set -profile="${profile_id}" -report-client-info=true -cache-size=10MB \
      -listen="localhost:53" -auto-activate=true
    sudo nextdns activate
    les_info "Configured NextDNS as the system DNS stub on localhost:53."
  fi

  sudo nextdns restart
}

les_dns_configure_dot_provider() {
  local provider="$1"
  local dns_servers=""

  case "${provider}" in
    Quad9)
      dns_servers="9.9.9.9#dns.quad9.net 149.112.112.112#dns.quad9.net"
      ;;
    AdGuard)
      dns_servers="94.140.14.14#dns.adguard-dns.com 94.140.15.15#dns.adguard-dns.com"
      ;;
    Cloudflare)
      dns_servers="1.1.1.1#cloudflare-dns.com 1.0.0.1#cloudflare-dns.com"
      ;;
    *)
      les_die "Unsupported DoT provider: ${provider}"
      ;;
  esac

  les_dns_write_resolved_dropin "${dns_servers}" "yes"
}

les_dns_configure_custom() {
  local custom_dns
  local dot_mode

  custom_dns="$(les_prompt "Enter DNS servers as systemd-resolved DNS= values (for example: 9.9.9.9#dns.quad9.net 149.112.112.112#dns.quad9.net)")"
  dot_mode="$(les_choose_from_menu "Use DNS-over-TLS?" "yes" "opportunistic" "no")"
  les_dns_write_resolved_dropin "${custom_dns}" "${dot_mode}"
}

les_dns_configure_interactive() {
  local provider
  local profile_id
  local nextdns_mode
  local listen_port
  local vpn_names

  vpn_names="$(les_detect_vpn || true)"
  if [[ -n "${vpn_names}" ]]; then
    les_warn "Detected active VPN connection(s): ${vpn_names}"
    les_warn "Local encrypted DNS clients may need compatibility mode."
  fi

  provider="$(les_dns_provider_menu)"
  case "${provider}" in
    NextDNS)
      profile_id="$(les_prompt "Enter your NextDNS profile ID")"
      nextdns_mode="$(les_choose_from_menu \
        "Choose a NextDNS mode" \
        "local-forwarder" \
        "system-stub")"
      listen_port="5354"
      if [[ "${nextdns_mode}" == "local-forwarder" ]]; then
        listen_port="$(les_prompt "Listener port for NextDNS local forwarder" "5354")"
      fi
      les_dns_configure_nextdns "${profile_id}" "${nextdns_mode}" "${listen_port}"
      ;;
    Quad9|AdGuard|Cloudflare)
      les_dns_configure_dot_provider "${provider}"
      ;;
    Custom)
      les_dns_configure_custom
      ;;
  esac

  les_dns_show_status
}

les_dns_show_status() {
  les_status_line "DNS stack" "$(if les_command_exists resolvectl; then echo systemd-resolved; else echo unknown; fi)"
  if les_command_exists nextdns; then
    les_status_line "NextDNS CLI" "$(nextdns status 2>/dev/null || true)"
  else
    les_status_line "NextDNS CLI" "not installed"
  fi

  if les_command_exists resolvectl; then
    les_status_line "Current DNS" "$(resolvectl status 2>/dev/null | awk -F': ' '/Current DNS Server/ {print $2; exit}')"
  fi

  if [[ -r "${LES_NEXTDNS_CONFIG}" ]]; then
    les_status_line "NextDNS config" "${LES_NEXTDNS_CONFIG}"
  fi
}
