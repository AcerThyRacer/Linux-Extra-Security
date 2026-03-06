# Providers

## NextDNS

Use `NextDNS` when you want:

- DNS-over-HTTPS
- profile-based filtering
- provider-side allow/block controls
- very large domain-scale blocking without forcing that logic into `UFW`

The toolkit prompts for your profile ID at runtime and never stores a real one in the repository.

### Modes

- `system-stub`: NextDNS owns localhost DNS directly.
- `local-forwarder`: NextDNS listens on a custom localhost port and another layer, such as Portmaster, forwards DNS to it.

Use `local-forwarder` when you intentionally want Portmaster in front of a local encrypted DNS client.

## Quad9

Configured through `systemd-resolved` with DNS-over-TLS.

Recommended when you want a strong default security-focused resolver without personal account setup.

## AdGuard

Configured through `systemd-resolved` with DNS-over-TLS.

Useful for a ready-made privacy and ad-blocking resolver without a separate local client.

## Cloudflare

Configured through `systemd-resolved` with DNS-over-TLS.

Best when you want a simple mainstream encrypted resolver and you are comfortable tuning blocking elsewhere.

## Custom

Custom mode writes your supplied `systemd-resolved` `DNS=` values and a chosen `DNSOverTLS=` policy. It is intended for advanced users who already know the server IPs and SNI values they need.

## Portmaster Compatibility Note

If Portmaster detects a localhost NextDNS forwarder, the toolkit defaults to a compatibility mode and avoids forcing DNS bypass prevention. This keeps encrypted DNS working instead of breaking the chain.

## Browser Compatibility Note

Browsers can bypass the OS resolver if Secure DNS or DNS-over-HTTPS is enabled internally. The toolkit documents this in reporting output and can install a managed Firefox policy to keep Firefox aligned with the system resolver.
