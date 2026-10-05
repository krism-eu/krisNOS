#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

exec nix build --no-update-lock-file -L .#iso --show-trace
