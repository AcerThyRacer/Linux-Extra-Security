#!/usr/bin/env bash
# Licensed under the Apache License, Version 2.0.

set -euo pipefail

# shellcheck source=./common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"
# shellcheck source=./package-install.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/package-install.sh"

LES_RESOLVED_DROPIN_DIR="/etc/systemd/resolved.conf.d"
LES_RESOLVED_DROPIN_FILE="${LES_RESOLVED_DROPIN_DIR}/99-linux-extra-security.conf"
LES_NEXTDNS_CONFIG="/etc/nextdns.conf"

les_dns_provider_menu() {
  les_choose_from_menu "Choose a DNS provider" "NextDNS" "Quad9" "AdGuard" "Cloudflare" "Custom"
}

les_dns_dot_servers() {
  case "$1" in
    Quad9)
      printf '%s\n' "9.9.9.9#dns.quad9.net 149.112.112.112#dns.quad9.net"
      ;;
    AdGuard)
      printf '%s\n' "94.140.14.14#dns.adguard-dns.com 94.140.15.15#dns.adguard-dns.com"
      ;;
    Cloudflare)
      printf '%s\n' "1.1.1.1#cloudflare-dns.com 1.0.0.1#cloudflare-dns.com"
      ;;
    *)
      les_die "Unsupported DoT provider: $1"
      ;;
  esac
}

les_dns_detect_stack() {
  if les_command_exists nextdns && [[ -r "${LES_NEXTDNS_CONFIG}" ]]; then
    printf 'nextdns-cli\n'
  elif les_command_exists resolvectl; then
    printf 'systemd-resolved\n'
  else
    printf 'unknown\n'
  fi
}

les_dns_detect_nextdns_forwarder_port() {
  if [[ -r "${LES_NEXTDNS_CONFIG}" ]]; then
    awk '/^listen 127\.0\.0\.1:/ {split($2, value, ":"); print value[2]; exit}' "${LES_NEXTDNS_CONFIG}"
  fi
}

les_dns_plan() {
  local provider="$1"
  local mode="${2:-dot}"
  local listen_port="${3:-5354}"

  les_section "DNS Plan"
  les_status_line "Current stack" "$(les_dns_detect_stack)"
  les_status_line "Requested provider" "${provider}"
  les_status_line "Mode" "${mode}"
  case "${provider}" in
    NextDNS)
      if [[ "${mode}" == "local-forwarder" ]]; then
        les_status_line "Listener" "127.0.0.1:${listen_port}"
        les_status_line "Compatibility" "Best with Portmaster forwarding and VPNs"
      else
        les_status_line "Listener" "localhost:53"
        les_status_line "Compatibility" "System stub mode for direct OS resolver use"
      fi
      ;;
    Custom)
      les_status_line "Managed file" "${LES_RESOLVED_DROPIN_FILE}"
      ;;
    *)
      les_status_line "Managed file" "${LES_RESOLVED_DROPIN_FILE}"
      les_status_line "Servers" "$(les_dns_dot_servers "${provider}")"
      ;;
  esac

  if [[ -n "$(les_detect_vpn | paste -sd ',' -)" ]]; then
    les_warn "VPN detected: prefer NextDNS local-forwarder mode or verify VPN DNS overrides after applying."
  fi
}

les_dns_install_nextdns() {
  les_require_sudo
  if les_command_exists nextdns; then
    les_info "NextDNS CLI is already installed."
    return 0
  fi

  les_info "Installing NextDNS CLI from the official Debian repository."
  if les_is_dry_run; then
    les_info "Would add NextDNS apt repository and install the nextdns package."
    return 0
  fi

  sudo wget -qO /usr/share/keyrings/nextdns.gpg https://repo.nextdns.io/nextdns.gpg
  printf 'deb [signed-by=/usr/share/keyrings/nextdns.gpg] https://repo.nextdns.io/deb stable main\n' |
    sudo tee /etc/apt/sources.list.d/nextdns.list >/dev/null
  sudo apt-get update
  sudo apt-get install -y nextdns
}

les_dns_write_resolved_dropin() {
  local dns_servers="$1"
  local dot_mode="$2"
  local manifest="$3"
  local content

  [[ -e "${LES_RESOLVED_DROPIN_FILE}" ]] && les_record_manifest_copy "${manifest}" "${LES_RESOLVED_DROPIN_FILE}"
  content="[Resolve]
DNS=${dns_servers}
FallbackDNS=
DNSOverTLS=${dot_mode}
DNSSEC=no
LLMNR=no
MulticastDNS=no"

  les_write_root_file "${LES_RESOLVED_DROPIN_FILE}" "${content}"
  les_run sudo systemctl restart systemd-resolved
}

les_dns_disable_resolved_dropin() {
  local manifest="$1"

  if [[ -e "${LES_RESOLVED_DROPIN_FILE}" ]]; then
    les_record_manifest_copy "${manifest}" "${LES_RESOLVED_DROPIN_FILE}"
    if les_is_dry_run; then
      les_info "Would remove ${LES_RESOLVED_DROPIN_FILE}"
    else
      les_require_sudo
      sudo rm -f "${LES_RESOLVED_DROPIN_FILE}"
    fi
    les_run sudo systemctl restart systemd-resolved
  fi
}

les_dns_configure_nextdns() {
  local profile_id="$1"
  local mode="$2"
  local listen_port="$3"
  local manifest="$4"

  les_dns_install_nextdns
  [[ -e "${LES_NEXTDNS_CONFIG}" ]] && les_record_manifest_copy "${manifest}" "${LES_NEXTDNS_CONFIG}"

  if les_is_dry_run; then
    les_info "Would stop and deactivate any existing NextDNS stub."
  else
    sudo nextdns stop >/dev/null 2>&1 || true
    sudo nextdns deactivate >/dev/null 2>&1 || true
  fi

  if [[ "${mode}" == "local-forwarder" ]]; then
    les_run sudo nextdns config set -profile="${profile_id}" -report-client-info=true -cache-size=10MB \
      -listen="127.0.0.1:${listen_port}" -auto-activate=false
    les_dns_disable_resolved_dropin "${manifest}"
  else
    les_run sudo nextdns config set -profile="${profile_id}" -report-client-info=true -cache-size=10MB \
      -listen="localhost:53" -auto-activate=true
    les_run sudo nextdns activate
  fi

  les_run sudo nextdns restart
}

les_dns_configure_dot_provider() {
  local provider="$1"
  local manifest="$2"
  les_dns_write_resolved_dropin "$(les_dns_dot_servers "${provider}")" "yes" "${manifest}"
}

les_dns_configure_custom() {
  local custom_dns="$1"
  local dot_mode="$2"
  local manifest="$3"
  les_dns_write_resolved_dropin "${custom_dns}" "${dot_mode}" "${manifest}"
}

les_dns_apply() {
  local provider="$1"
  local profile_id="${2:-}"
  local mode="${3:-dot}"
  local listen_port="${4:-5354}"
  local custom_dns="${5:-}"
  local dot_mode="${6:-yes}"
  local manifest

  manifest="$(les_new_manifest dns)"
  les_write_state_file "latest-dns-manifest" "${manifest}"
  les_write_state_file "dns-last-provider" "${provider}"

  case "${provider}" in
    NextDNS)
      [[ -n "${profile_id}" ]] || les_die "NextDNS profile ID is required."
      les_dns_configure_nextdns "${profile_id}" "${mode}" "${listen_port}" "${manifest}"
      ;;
    Quad9|AdGuard|Cloudflare)
      les_dns_configure_dot_provider "${provider}" "${manifest}"
      ;;
    Custom)
      [[ -n "${custom_dns}" ]] || les_die "Custom DNS values are required."
      les_dns_configure_custom "${custom_dns}" "${dot_mode}" "${manifest}"
      ;;
    *)
      les_die "Unsupported provider: ${provider}"
      ;;
  esac
}

les_dns_apply_profile() {
  local profile_name="$1"
  local nextdns_profile_id="${2:-}"

  les_load_profile "${profile_name}"
  les_dns_plan "${DNS_PROVIDER}" "${NEXTDNS_MODE:-${DNS_MODE}}" "${NEXTDNS_LISTEN_PORT:-5354}"
  case "${DNS_PROVIDER}" in
    NextDNS)
      if [[ -z "${nextdns_profile_id}" ]]; then
        nextdns_profile_id="$(les_prompt "Enter your NextDNS profile ID")"
      fi
      les_dns_apply "${DNS_PROVIDER}" "${nextdns_profile_id}" "${NEXTDNS_MODE:-local-forwarder}" "${NEXTDNS_LISTEN_PORT:-5354}"
      ;;
    *)
      les_dns_apply "${DNS_PROVIDER}" "" "${DNS_MODE:-dot}"
      ;;
  esac
}

les_dns_browser_bypass_hints() {
  les_section "Browser DNS Bypass Hints"
  les_note "Firefox should keep DNS-over-HTTPS disabled or managed by policy."
  les_note "Chromium-based browsers should use the system resolver instead of a built-in Secure DNS provider."
}

les_dns_verify() {
  les_section "DNS Verification"
  if les_command_exists dig; then
    if dig @1.1.1.1 example.com +time=2 +tries=1 >/dev/null 2>&1; then
      les_warn "Direct plaintext DNS is reachable from this host."
    else
      les_info "Direct plaintext DNS appears blocked or unreachable."
    fi
  fi

  if les_command_exists curl && [[ -r "${LES_NEXTDNS_CONFIG}" ]]; then
    les_status_line "NextDNS test" "$(curl -fsSL https://test.nextdns.io 2>/dev/null || echo unavailable)"
  fi
}

les_dns_configure_interactive() {
  local provider
  local profile_id=""
  local nextdns_mode="local-forwarder"
  local listen_port="5354"
  local custom_dns=""
  local dot_mode="yes"

  provider="$(les_dns_provider_menu)"
  case "${provider}" in
    NextDNS)
      profile_id="$(les_prompt "Enter your NextDNS profile ID")"
      nextdns_mode="$(les_choose_from_menu "Choose a NextDNS mode" "local-forwarder" "system-stub")"
      [[ "${nextdns_mode}" == "local-forwarder" ]] && listen_port="$(les_prompt "Listener port for NextDNS local forwarder" "5354")"
      les_dns_plan "${provider}" "${nextdns_mode}" "${listen_port}"
      les_confirm "Apply this DNS plan?" || return 1
      les_dns_apply "${provider}" "${profile_id}" "${nextdns_mode}" "${listen_port}"
      ;;
    Quad9|AdGuard|Cloudflare)
      les_dns_plan "${provider}" "dot"
      les_confirm "Apply this DNS plan?" || return 1
      les_dns_apply "${provider}"
      ;;
    Custom)
      custom_dns="$(les_prompt "Enter DNS servers as systemd-resolved DNS= values")"
      dot_mode="$(les_choose_from_menu "Use DNS-over-TLS?" "yes" "opportunistic" "no")"
      les_dns_plan "${provider}" "custom"
      les_confirm "Apply this DNS plan?" || return 1
      les_dns_apply "${provider}" "" "custom" "" "${custom_dns}" "${dot_mode}"
      ;;
  esac

  les_dns_show_status
}

les_dns_show_status() {
  les_section "DNS Status"
  les_status_line "DNS stack" "$(les_dns_detect_stack)"
  if les_command_exists nextdns; then
    les_status_line "NextDNS CLI" "$(nextdns status 2>/dev/null || true)"
  else
    les_status_line "NextDNS CLI" "not installed"
  fi

  if les_command_exists resolvectl; then
    les_status_line "Current DNS" "$(resolvectl status 2>/dev/null | awk -F': ' '/Current DNS Server/ {print $2; exit}' || true)"
  fi

  if [[ -r "${LES_NEXTDNS_CONFIG}" ]]; then
    les_status_line "NextDNS config" "${LES_NEXTDNS_CONFIG}"
  fi

  [[ -r "${LES_RESOLVED_DROPIN_FILE}" ]] && les_status_line "resolved drop-in" "${LES_RESOLVED_DROPIN_FILE}"
}
