#!/usr/bin/env bash
set -euo pipefail

REPO="${KRISOS_CONFIG_REPO:-$HOME/krisNOS-config}"
HOST="${KRISOS_HOST:-$(hostname -s)}"
DEFAULT_REMOTE="${KRISOS_CONFIG_REMOTE:-https://github.com/krism-eu/krisNOS-config.git}"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/krisos"
STATE_FILE="$STATE_DIR/config-sync.state"

usage() {
  cat <<'USAGE'
Usage:
  kris-configctl init [git-url]
  kris-configctl status [--json]
  kris-configctl fetch
  kris-configctl diff
  kris-configctl pull
  kris-configctl push
  kris-configctl sync
  kris-configctl validate
  kris-configctl build
  kris-configctl apply

Environment:
  KRISOS_CONFIG_REPO     local working tree (default: ~/krisNOS-config)
  KRISOS_CONFIG_REMOTE   clone URL used by init (default: krism-eu/krisNOS-config)
  KRISOS_HOST            NixOS flake host name (default: current short hostname)

Safety rules:
- synchronization is never automatic;
- never force-pushes or auto-merges diverged histories;
- never overwrites a dirty working tree;
- pull is fast-forward only;
- build validates first and does not need root;
- apply is separate and validates before switching.
USAGE
}

die() { printf 'kris-configctl: %s\n' "$*" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || die "comando richiesto non trovato: $1"; }
repo_ok() { [ -d "$REPO/.git" ] || die "repo locale non inizializzato: $REPO"; }
gitc() { git -C "$REPO" "$@"; }
branch_name() { gitc symbolic-ref --quiet --short HEAD 2>/dev/null || printf 'DETACHED\n'; }
head_sha() { gitc rev-parse --verify HEAD; }
upstream_name() { gitc rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || true; }

dirty_flag() {
  if [ -n "$(gitc status --porcelain=v1 --untracked-files=normal)" ]; then printf 'true\n'; else printf 'false\n'; fi
}

ahead_behind() {
  local up
  up="$(upstream_name)"
  if [ -z "$up" ]; then printf '0 0\n'; return; fi
  gitc rev-list --left-right --count "HEAD...$up" | awk '{print $1, $2}'
}

state_value() {
  local key="$1"
  [ -r "$STATE_FILE" ] || return 0
  sed -n "s/^${key}=//p" "$STATE_FILE" | tail -n 1
}

status_json() {
  local branch head up dirty ahead behind applied applied_at
  branch="$(branch_name)"; head="$(head_sha)"; up="$(upstream_name)"; dirty="$(dirty_flag)"
  read -r ahead behind < <(ahead_behind)
  applied="$(state_value commit || true)"; applied_at="$(state_value applied_at || true)"
  printf '{"schema":2,"repo":"%s","branch":"%s","head":"%s","upstream":"%s","dirty":%s,"ahead":%s,"behind":%s,"host":"%s","appliedCommit":"%s","appliedAt":"%s"}\n' \
    "${REPO//\"/\\\"}" "${branch//\"/\\\"}" "$head" "${up//\"/\\\"}" "$dirty" "$ahead" "$behind" "${HOST//\"/\\\"}" "${applied//\"/\\\"}" "${applied_at//\"/\\\"}"
}

status_text() {
  local ahead behind
  read -r ahead behind < <(ahead_behind)
  printf 'repo=%s\nbranch=%s\nhead=%s\nupstream=%s\ndirty=%s\n' "$REPO" "$(branch_name)" "$(head_sha)" "$(upstream_name)" "$(dirty_flag)"
  printf 'ahead=%s\nbehind=%s\nhost=%s\n' "$ahead" "$behind" "$HOST"
  printf 'appliedCommit=%s\nappliedAt=%s\n' "$(state_value commit || true)" "$(state_value applied_at || true)"
}

require_clean() { [ "$(dirty_flag)" = false ] || die "working tree modificato: commit/stash/ripristina prima della sync"; }

fetch_remote() {
  local up
  up="$(upstream_name)"
  [ -n "$up" ] || die "nessun upstream configurato per il branch corrente"
  gitc fetch --prune --tags
}

show_diff() {
  local up ahead behind shown=0
  if [ "$(dirty_flag)" = true ]; then
    printf '=== Modifiche locali non committate ===\n'
    gitc diff --no-ext-diff --no-color
    gitc diff --cached --no-ext-diff --no-color
    shown=1
  fi
  up="$(upstream_name)"
  if [ -n "$up" ]; then
    read -r ahead behind < <(ahead_behind)
    if [ "$behind" -gt 0 ]; then
      printf '%s\n' '=== Modifiche presenti su GitHub ==='
      gitc diff --no-ext-diff --no-color "HEAD..$up"
      shown=1
    fi
    if [ "$ahead" -gt 0 ]; then
      printf '%s\n' '=== Modifiche locali già committate da inviare ==='
      gitc diff --no-ext-diff --no-color "$up..HEAD"
      shown=1
    fi
  fi
  [ "$shown" -eq 1 ] || printf 'Nessuna differenza da mostrare.\n'
}

safe_pull() {
  local up ahead behind
  require_clean
  up="$(upstream_name)"; [ -n "$up" ] || die "nessun upstream configurato"
  read -r ahead behind < <(ahead_behind)
  if [ "$ahead" -gt 0 ] && [ "$behind" -gt 0 ]; then die "storia divergente: nessun merge automatico"; fi
  if [ "$behind" -eq 0 ]; then printf 'Già aggiornato.\n'; return; fi
  [ "$ahead" -eq 0 ] || die "branch locale avanti: pull automatico rifiutato"
  gitc merge --ff-only "$up"
}

safe_push() {
  local up ahead behind
  require_clean
  up="$(upstream_name)"; [ -n "$up" ] || die "nessun upstream configurato"
  gitc fetch --prune
  read -r ahead behind < <(ahead_behind)
  [ "$behind" -eq 0 ] || die "remote più avanti o divergente: sincronizza prima di push"
  if [ "$ahead" -eq 0 ]; then printf 'Niente da inviare.\n'; return; fi
  gitc push
}

safe_sync() {
  local ahead behind
  require_clean
  fetch_remote
  read -r ahead behind < <(ahead_behind)
  if [ "$ahead" -gt 0 ] && [ "$behind" -gt 0 ]; then
    die "storia divergente: intervento manuale richiesto"
  elif [ "$behind" -gt 0 ]; then
    safe_pull
  elif [ "$ahead" -gt 0 ]; then
    safe_push
  else
    printf 'Locale e remoto sono allineati.\n'
  fi
}

mode() {
  if [ -f "$REPO/flake.nix" ]; then printf 'flake\n'
  elif [ -f "$REPO/configuration.nix" ]; then printf 'classic\n'
  else die "manca flake.nix o configuration.nix nel repo"
  fi
}

validate_config() {
  need nix
  case "$(mode)" in
    flake) nix eval --raw "$REPO#nixosConfigurations.$HOST.config.system.build.toplevel.drvPath" >/dev/null ;;
    classic)
      need nix-instantiate
      nix-instantiate '<nixpkgs/nixos>' -A system -I "nixos-config=$REPO/configuration.nix" >/dev/null
      ;;
  esac
  printf 'Validazione OK.\n'
}

build_config() {
  validate_config
  case "$(mode)" in
    flake)
      nix build --no-link "$REPO#nixosConfigurations.$HOST.config.system.build.toplevel"
      ;;
    classic)
      need nix-build
      nix-build '<nixpkgs/nixos>' -A system -I "nixos-config=$REPO/configuration.nix" --no-out-link
      ;;
  esac
  printf 'Build OK. Nessuna modifica applicata al sistema.\n'
}

record_applied() {
  mkdir -p "$STATE_DIR"
  printf 'commit=%s\napplied_at=%s\n' "$(head_sha)" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$STATE_FILE"
}

apply_config() {
  need nixos-rebuild
  validate_config
  case "$(mode)" in
    flake) sudo nixos-rebuild switch --flake "$REPO#$HOST" ;;
    classic) sudo nixos-rebuild switch -I "nixos-config=$REPO/configuration.nix" ;;
  esac
  record_applied
  printf 'Applicata configurazione commit %s\n' "$(head_sha)"
}

cmd="${1:-}"
case "$cmd" in
  init)
    [ "$#" -le 2 ] || { usage >&2; exit 2; }
    need git
    [ ! -e "$REPO" ] || die "destinazione già esistente: $REPO"
    git clone -- "${2:-$DEFAULT_REMOTE}" "$REPO"
    ;;
  status)
    [ "$#" -le 2 ] || { usage >&2; exit 2; }
    need git; repo_ok
    if [ "${2:-}" = --json ]; then status_json; else status_text; fi
    ;;
  fetch) [ "$#" -eq 1 ] || { usage >&2; exit 2; }; need git; repo_ok; fetch_remote ;;
  diff) [ "$#" -eq 1 ] || { usage >&2; exit 2; }; need git; repo_ok; show_diff ;;
  pull) [ "$#" -eq 1 ] || { usage >&2; exit 2; }; need git; repo_ok; fetch_remote; safe_pull ;;
  push) [ "$#" -eq 1 ] || { usage >&2; exit 2; }; need git; repo_ok; safe_push ;;
  sync) [ "$#" -eq 1 ] || { usage >&2; exit 2; }; need git; repo_ok; safe_sync ;;
  validate) [ "$#" -eq 1 ] || { usage >&2; exit 2; }; need git; repo_ok; validate_config ;;
  build) [ "$#" -eq 1 ] || { usage >&2; exit 2; }; need git; repo_ok; build_config ;;
  apply) [ "$#" -eq 1 ] || { usage >&2; exit 2; }; need git; repo_ok; require_clean; apply_config ;;
  -h|--help|help|'') usage ;;
  *) usage >&2; exit 2 ;;
esac
