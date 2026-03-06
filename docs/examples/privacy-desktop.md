# Example: Privacy Desktop

Goal: harden a general desktop without going straight to the most disruptive profile.

```bash
./bin/linux-extra-security install-tools all
./bin/linux-extra-security profile plan balanced-desktop
./bin/linux-extra-security profile apply balanced-desktop
./bin/linux-extra-security verify all
```
