# krisNOS kernel hardening plan

Goal: add conservative desktop hardening without breaking the features that krisNOS actually uses.

## Current implementation status

The current framework applies a small conservative hardening profile by default. It does **not** yet expose a dedicated `krisos.*` enable/disable option or a krisNCC toggle; the section below is explicitly roadmap, not a promise of current UI functionality.

The existing sysctl values are `mkDefault` values, so personal declarative configuration can override individual settings without patching the framework. A future single profile option should be added only together with the corresponding krisNCC control and tests.

## Compatibility constraints

The hardening profile must preserve:

- AMD Cezanne / amdgpu;
- Plasma 6 Wayland;
- Flatpak;
- Distrobox with rootless Podman;
- Bluetooth and PipeWire;
- normal USB/storage hotplug;
- the existing NixOS rollback model.

For that reason the first profile must not disable user namespaces, must not lock kernel-module loading after boot, and must not replace the distribution kernel with a hardened/custom kernel.

## Proposed model

Hardening belongs to the declarative configuration, not to one-shot runtime sysctl commands in krisNCC.

krisNCC should eventually expose one compact section that:

1. shows whether the desktop hardening profile is enabled;
2. shows the important effective values read-only;
3. changes the declarative krisNOS-config option;
4. uses the existing validate/build/apply path;
5. keeps an expandable details view instead of exposing dozens of independent toggles.

## Conservative candidate set

Values to verify against the pinned NixOS 26.05 configuration before enabling:

- `kernel.kptr_restrict = 2`;
- `kernel.dmesg_restrict = 1`;
- `kernel.yama.ptrace_scope = 1`;
- `kernel.unprivileged_bpf_disabled = 1`;
- `fs.protected_hardlinks = 1`;
- `fs.protected_symlinks = 1`;
- `fs.protected_fifos = 2`;
- `fs.protected_regular = 2`;
- `fs.suid_dumpable = 0`;
- `vm.unprivileged_userfaultfd = 0`;
- disable IPv4/IPv6 ICMP redirects and source routing where compatible;
- keep `net.ipv4.tcp_syncookies = 1`.

## Separate decisions

Evaluate AppArmor separately. It fits the krisNOS preference better than SELinux, but it should be enabled only after confirming the NixOS 26.05 desktop/Flatpak/Distrobox policy behavior.

Do not include in the default profile without a specific reason and hardware test:

- `linuxPackages_hardened` or a custom kernel;
- disabling unprivileged user namespaces;
- permanent kernel-module locking;
- aggressive LSM/module blacklists;
- speculative mitigations with measurable desktop performance or compatibility cost.

The target is a small, reviewable desktop-hardening profile, not a generic CIS/STIG policy layer.
