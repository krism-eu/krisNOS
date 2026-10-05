#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
exec nixos-rebuild build-image --image-variant iso-installer --flake .#krisos-live --show-trace
