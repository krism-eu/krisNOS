#!/usr/bin/env bash
set -euo pipefail

IMAGE="${KRISNOS_NIX_IMAGE:-docker.io/nixos/nix:2.35.2}"
CONTAINER="${KRISNOS_NIX_CONTAINER:-krisnos-nix-builder}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_ROOT="${KRISNOS_CONFIG_ROOT:-$ROOT/../krisNOS-config}"
MODE="${1:-cc}"

need() {
  command -v "$1" >/dev/null 2>&1 || {
    printf 'Manca il comando richiesto: %s\n' "$1" >&2
    exit 127
  }
}

need podman

create_builder() {
  printf '==> Creo builder persistente %s da %s\n' "$CONTAINER" "$IMAGE"
  podman pull "$IMAGE"

  args=(
    create
    --name "$CONTAINER"
    --security-opt label=disable
    --workdir /src
    --volume "$ROOT:/src:ro"
  )

  if [ -d "$CONFIG_ROOT/.git" ]; then
    args+=(--volume "$CONFIG_ROOT:/config:ro")
  fi

  args+=(
    --entrypoint /bin/sh
    "$IMAGE"
    -lc 'trap : TERM INT; while :; do sleep 3600; done'
  )

  podman "${args[@]}" >/dev/null
}

ensure_builder() {
  if ! podman container exists "$CONTAINER"; then
    create_builder
  fi

  if [ "$(podman inspect -f '{{.State.Running}}' "$CONTAINER")" != true ]; then
    podman start "$CONTAINER" >/dev/null
  fi
}

nix_exec() {
  podman exec \
    -e NIX_CONFIG=$'experimental-features = nix-command flakes\nsandbox = false\naccept-flake-config = true' \
    "$CONTAINER" \
    nix "$@"
}

check_eval() {
  printf '\n==> Valutazione flake krisNOS (nessun build)\n'
  nix_exec flake check --no-build --show-trace /src
}

build_cc() {
  printf '\n==> Build krisNCC\n'
  nix_exec build -L --no-link /src#krisNCC
}

build_live() {
  printf '\n==> Build sistema live NixOS\n'
  nix_exec build -L --no-link /src#checks.x86_64-linux.live-system
}

build_iso() {
  printf '\n==> Build ISO krisNOS\n'
  nix_exec build -L --no-link /src#iso
}

check_config() {
  if [ ! -d "$CONFIG_ROOT/.git" ]; then
    printf 'krisNOS-config non trovato in %s\n' "$CONFIG_ROOT" >&2
    printf 'Clonalo accanto a krisNOS oppure imposta KRISNOS_CONFIG_ROOT.\n' >&2
    exit 2
  fi

  if ! podman inspect "$CONTAINER" --format '{{range .Mounts}}{{println .Destination}}{{end}}' | grep -Fxq /config; then
    printf '==> Ricreo il builder per aggiungere il mount /config\n'
    podman rm -f "$CONTAINER" >/dev/null
    create_builder
    podman start "$CONTAINER" >/dev/null
  fi

  printf '\n==> Valutazione krisNOS-config usando il krisNOS locale\n'
  nix_exec flake check --no-build --show-trace /config --override-input krisNOS /src
}

case "$MODE" in
  cc)
    ensure_builder
    check_eval
    build_cc
    ;;
  system)
    ensure_builder
    check_eval
    build_live
    ;;
  config)
    ensure_builder
    check_config
    ;;
  iso)
    ensure_builder
    check_eval
    build_iso
    ;;
  all)
    ensure_builder
    check_eval
    build_cc
    check_config
    build_live
    build_iso
    ;;
  shell)
    ensure_builder
    exec podman exec -it "$CONTAINER" /bin/sh
    ;;
  stop)
    if podman container exists "$CONTAINER"; then
      podman stop "$CONTAINER" >/dev/null
    fi
    ;;
  reset)
    if podman container exists "$CONTAINER"; then
      podman rm -f "$CONTAINER" >/dev/null
    fi
    printf 'Builder rimosso. Il prossimo test riparte dall’immagine pulita.\n'
    ;;
  *)
    cat >&2 <<'USAGE'
Uso: scripts/test-podman.sh [cc|system|config|iso|all|shell|stop|reset]

  cc      evalua il flake e costruisce krisNCC
  system  evalua e costruisce il toplevel del sistema live
  config  valuta krisNOS-config contro il checkout krisNOS locale
  iso     costruisce l'immagine ISO
  all     esegue tutti i gate sopra
  shell   apre una shell nel builder persistente
  stop    ferma il builder, conservandone lo store Nix
  reset   elimina il builder e la cache dei build
USAGE
    exit 2
    ;;
esac
