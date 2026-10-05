#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
exec nixos-rebuild build-vm --flake .#krisos-live --show-trace
