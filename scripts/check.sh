#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

printf '%s\n' '==> lock file is complete and immutable during checks'
nix flake metadata --no-update-lock-file >/dev/null

printf '%s\n' '==> formatting check'
nix fmt --no-update-lock-file -- --check .

printf '%s\n' '==> flake checks'
nix flake check --no-update-lock-file --show-trace

printf '%s\n' '==> evaluate ISO derivation'
nix eval --no-update-lock-file --raw .#packages.x86_64-linux.iso.drvPath >/dev/null

printf '%s\n' '==> evaluate VM derivation'
nix eval --no-update-lock-file --raw .#packages.x86_64-linux.vm.drvPath >/dev/null

printf '%s\n' 'OK'
