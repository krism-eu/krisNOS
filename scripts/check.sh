#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

printf '%s\n' '==> formatting check'
nix fmt -- --check .

printf '%s\n' '==> flake checks'
nix flake check --show-trace

printf '%s\n' '==> evaluate ISO derivation'
nix eval --raw .#packages.x86_64-linux.iso.drvPath >/dev/null

printf '%s\n' '==> evaluate VM derivation'
nix eval --raw .#packages.x86_64-linux.vm.drvPath >/dev/null

printf '%s\n' 'OK'
