#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

printf '%s\n' '==> formatting check'
nix fmt -- --check .

printf '%s\n' '==> flake checks'
nix flake check --show-trace

printf '%s\n' '==> evaluate ISO image'
nix eval .#nixosConfigurations.krisos-live.config.system.build.images.iso-installer.drvPath >/dev/null

printf '%s\n' 'OK'
