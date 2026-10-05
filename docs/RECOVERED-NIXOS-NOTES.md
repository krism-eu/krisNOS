# Recovered historical NixOS notes

This file records useful intent recovered from old NixOS configuration fragments. It is **not** source-of-truth configuration and must not be copied verbatim into krisNOS. Every item is re-evaluated against current NixOS 26.05 and the krisNOS architecture.

## Recovered intent

### Audio
- PipeWire as the only audio server.
- ALSA + PulseAudio compatibility through PipeWire.
- `rtkit` enabled.
- Do **not** restore `alsa.support32Bit` by default: krisNOS deliberately avoids 32-bit/i686 support unless a concrete application requires it.
- WirePlumber remains the policy/session manager.

Current krisNOS already implements this model.

### Memory
- ZRAM was intentionally enabled.
- Historical config also enabled `systemd.oomd`.
- Current krisNOS already uses ZRAM with zstd and an explicit memory percentage.
- `systemd.oomd` should be evaluated separately before enabling: it changes memory-pressure kill policy and must be tested with Plasma, user sessions and ZRAM rather than copied blindly.

### Printing and Flatpak
- CUPS and Flatpak were intentionally available in the base.
- Keep them as infrastructure.
- Printer queues/settings remain native mutable CUPS state; Flatpak apps remain mutable user software.

### Services deliberately not part of the desktop base
Historical intent was to avoid unnecessary background services such as SSH, SSSD, ModemManager, speech-dispatcher and fwupd when not needed.

krisNOS policy:
- do not install/enable an unnecessary component in the first place;
- avoid brittle `systemd.services.<name>.enable = false` overrides for services that are not otherwise part of the base;
- SSH remains explicitly disabled because it is a meaningful security boundary;
- decide fwupd separately: firmware-update capability can be useful even if no resident daemon is desired;
- do not add SSSD/ModemManager/speech-dispatcher unless a real requirement appears.

### Bluetooth and Wi-Fi
Recovered intent:
- Bluetooth available but radio off by default;
- Wi-Fi power saving enabled;
- old config forced both Wi-Fi and Bluetooth into rfkill blocked state on every boot.

krisNOS adaptation:
- keep BlueZ installed and Bluetooth power-on-boot configurable (currently default off);
- use BlueZ/rfkill for immediate Bluetooth state;
- use NetworkManager for Wi-Fi state and power policy;
- **do not restore a custom boot oneshot that forcibly blocks both radios every boot**. It would override user/runtime intent, add another custom service, and conflict with the new mutable-state model.
- if a default-off Wi-Fi policy is still desired, implement it through NetworkManager/krisNCC with native persistence rather than a parallel boot service.

### Journald
Recovered intent was bounded logs: small disk usage and finite retention.

Keep the intent, not the old block verbatim.

Candidate policy to evaluate for the installed system:
- bounded `SystemMaxUse`;
- `SystemKeepFree` reserve;
- finite `MaxRetentionSec`;
- avoid contradictory/redundant limits.

Important: the historical `LogFilterPatterns=` lines were placed in `services.journald.extraConfig`. `LogFilterPatterns=` belongs to per-unit systemd execution/log filtering, not to the normal journald.conf storage/retention policy. Do not restore those lines there. If a noisy unit genuinely needs filtering, treat it individually and only after confirming the message is harmless.

Enterprise-style rule for krisNOS: prefer fixing/removing a noisy service over globally hiding its warnings.

### Logrotate
Historical intent was aggressive global rotation (`daily`, two rotations, compression, 50 MiB max).

Do not restore it globally without evidence. Most core diagnostics are in journald, while individual packages may already ship correct rotation policy. A global override can unexpectedly weaken retention for useful service logs.

## Architectural classification

| Recovered setting | krisNOS ownership |
| --- | --- |
| PipeWire/WirePlumber availability | Foundation (Nix) |
| Active audio device/volume/routes | Native mutable state |
| ZRAM implementation | Foundation (Nix) |
| systemd-oomd | Foundation policy, pending test |
| CUPS availability | Foundation (Nix) |
| Printer queues/default printer | Native mutable CUPS state |
| Flatpak availability | Foundation (Nix) |
| Flatpak applications | Mutable user state |
| BlueZ availability | Foundation (Nix) |
| Bluetooth radio/pairings | Native mutable state |
| NetworkManager availability | Foundation (Nix) |
| Wi-Fi connections/radio | Native mutable state |
| Wi-Fi power policy | Prefer native NetworkManager state/policy |
| SSH server availability | Foundation security policy (off) |
| Journal size/retention | Foundation diagnostics policy |
| Per-unit log filtering | Exceptional, unit-specific only |

## Rule for future recovered fragments

When another old fragment is found, first recover its **intent**. Then classify it as:
1. foundation;
2. native mutable state;
3. user software/state;
4. personal structural configuration;
5. obsolete/custom workaround.

Only then decide whether any code belongs in krisNOS or krisNCC.
