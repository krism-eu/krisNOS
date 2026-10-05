# Testing krisNOS from Fedora with Podman

The development host can remain Fedora. krisNOS build/evaluation tests run in a persistent rootless Podman container using the official `nixos/nix` image.

Distrobox is **not** used for the NixOS builder: Distrobox supports NixOS as a host, but NixOS is not a supported guest/container distro. Distrobox remains part of the future krisNOS user experience for normal mutable environments such as Fedora, Arch or Debian.

## Why a persistent Podman builder

- no Nix installation is required on Fedora;
- the Fedora host is not modified by NixOS tests;
- `/src` is mounted read-only from the local `krisNOS` checkout;
- the container itself persists, so `/nix/store` and downloaded build dependencies are reused;
- `stop` frees RAM/CPU while keeping the build cache;
- `reset` removes the builder and starts from a clean Nix store when needed.

The official `nixos/nix` container disables Nix sandboxing by default. This is suitable for the first build/evaluation gate, but it is not the final runtime test. Boot, systemd, Polkit, NetworkManager, CUPS, BlueZ and other whole-system behavior must later be tested in a NixOS VM and finally on the target machine.

## Fedora prerequisites

Only Podman is required on the host.

Keep the repositories side by side when testing both:

```text
~/src/krisNOS/
~/src/krisNOS-config/
```

Checkout the krisNCC work branch in `krisNOS` while it is under development.

## Commands

From the `krisNOS` repository:

```bash
./scripts/test-podman.sh cc
```

This performs Nix flake evaluation and builds `krisNCC`.

Additional gates:

```bash
./scripts/test-podman.sh config
./scripts/test-podman.sh system
./scripts/test-podman.sh iso
./scripts/test-podman.sh all
```

Maintenance:

```bash
./scripts/test-podman.sh shell
./scripts/test-podman.sh stop
./scripts/test-podman.sh reset
```

`config` evaluates the sibling `krisNOS-config` checkout while overriding its `krisNOS` input with `/src`, so the personal configuration is tested against the current local work branch rather than GitHub `main`.

## Gate order

1. `cc`: evaluate the flake and compile krisNCC.
2. `config`: evaluate the personal configuration against the same local framework.
3. `system`: build the complete NixOS live toplevel.
4. `iso`: build the native NixOS installer image.
5. VM/KVM: boot and test system services, Polkit and graphical integration.
6. Physical target only after the previous gates pass.

No GitHub Action is required for this workflow.
