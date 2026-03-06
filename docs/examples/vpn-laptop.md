# Example: VPN Laptop

Goal: keep a laptop in a VPN-oriented posture while still using a filtered resolver.

```bash
./bin/linux-extra-security profile plan vpn-friendly
./bin/linux-extra-security profile apply vpn-friendly
./bin/linux-extra-security firewall verify
./bin/linux-extra-security verify all
```
