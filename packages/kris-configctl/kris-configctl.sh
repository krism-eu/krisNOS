set -euo pipefail

REPO="${KRISOS_CONFIG_REPO:-$HOME/krisNOS-config}"
HOST="${KRISOS_HOST:-$(cut -d. -f1 </proc/sys/kernel/hostname)}"
DEFAULT_REMOTE="${KRISOS_CONFIG_REMOTE:-https://github.com/krism-eu/krisNOS-config.git}"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/krisos"
STATE_FILE="$STATE_DIR/config-sync.state"
PENDING_LINK="$STATE_DIR/pending-system"

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

Internal krisNCC commands:
  kris-configctl prepare-apply --json
  kris-configctl record-applied <commit> <toplevel>

Environment:
  KRISOS_CONFIG_REPO     local working tree (default: ~/krisNOS-config)
  KRISOS_CONFIG_REMOTE   clone URL used by init (default: krism-eu/krisNOS-config)
  KRISOS_HOST            NixOS flake host name (default: current short hostname)
  KRISOS_NONINTERACTIVE  when 1, network Git operations cannot prompt and time out

Safety rules:
- synchronization is never automatic;
- never force-pushes or auto-merges diverged histories;
- never overwrites a dirty working tree;
- pull is fast-forward only;
- validate/build/apply refuse lock-file updates;
- build validates first and does not need root;
- apply is separate and validates before switching.
USAGE
}

die() { printf 'kris-configctl: %s\n' "$*" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || die "comando richiesto non trovato: $1"; }
repo_ok() { [ -d "$REPO/.git" ] || die "repo locale non inizializzato: $REPO"; }
gitc() { git -C "$REPO" "$@"; }

git_network() {
  if [ "${KRISOS_NONINTERACTIVE:-0}" = 1 ]; then
    GIT_TERMINAL_PROMPT=0 timeout 45s \
      git -c http.lowSpeedLimit=1000 -c http.lowSpeedTime=30 -C "$REPO" "$@"
  else
    gitc "$@"
  fi
}

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

current_system() {
  readlink -f /run/current-system 2>/dev/null || true
}

current_applied_state() {
  local recorded_commit recorded_toplevel recorded_at current
  recorded_commit="$(state_value commit || true)"
  recorded_toplevel="$(state_value toplevel || true)"
  recorded_at="$(state_value applied_at || true)"
  current="$(current_system)"

  if [ -n "$recorded_commit" ] && [ -n "$recorded_toplevel" ] \
      && [ "$current" = "$recorded_toplevel" ]; then
    printf '%s|%s|%s\n' "$recorded_commit" "$recorded_toplevel" "$recorded_at"
  else
    printf '||\n'
  fi
}

status_json() {
  local branch head up dirty ahead behind applied applied_toplevel applied_at current
  need jq
  branch="$(branch_name)"
  head="$(head_sha)"
  up="$(upstream_name)"
  dirty="$(dirty_flag)"
  read -r ahead behind < <(ahead_behind)
  IFS='|' read -r applied applied_toplevel applied_at < <(current_applied_state)
  current="$(current_system)"

  jq -cn \
    --arg repo "$REPO" \
    --arg branch "$branch" \
    --arg head "$head" \
    --arg upstream "$up" \
    --argjson dirty "$dirty" \
    --argjson ahead "$ahead" \
    --argjson behind "$behind" \
    --arg host "$HOST" \
    --arg appliedCommit "$applied" \
    --arg appliedToplevel "$applied_toplevel" \
    --arg appliedAt "$applied_at" \
    --arg currentToplevel "$current" \
    '{
      schema: 2,
      repo: $repo,
      branch: $branch,
      head: $head,
      upstream: $upstream,
      dirty: $dirty,
      ahead: $ahead,
      behind: $behind,
      host: $host,
      appliedCommit: $appliedCommit,
      appliedToplevel: $appliedToplevel,
      appliedAt: $appliedAt,
      currentToplevel: $currentToplevel
    }'
}

status_text() {
  local ahead behind applied applied_toplevel applied_at
  read -r ahead behind < <(ahead_behind)
  IFS='|' read -r applied applied_toplevel applied_at < <(current_applied_state)
  printf 'repo=%s\nbranch=%s\nhead=%s\nupstream=%s\ndirty=%s\n' "$REPO" "$(branch_name)" "$(head_sha)" "$(upstream_name)" "$(dirty_flag)"
  printf 'ahead=%s\nbehind=%s\nhost=%s\n' "$ahead" "$behind" "$HOST"
  printf 'appliedCommit=%s\nappliedToplevel=%s\nappliedAt=%s\ncurrentToplevel=%s\n' \
    "$applied" "$applied_toplevel" "$applied_at" "$(current_system)"
}

require_clean() { [ "$(dirty_flag)" = false ] || die "working tree modificato: commit/stash/ripristina prima dell'operazione"; }

fetch_remote() {
  local up
  up="$(upstream_name)"
  [ -n "$up" ] || die "nessun upstream configurato per il branch corrente"
  git_network fetch --prune --tags
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
  else
    printf '%s\n' 'Nessun upstream configurato per il branch corrente.'
    shown=1
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
  git_network fetch --prune
  read -r ahead behind < <(ahead_behind)
  [ "$behind" -eq 0 ] || die "remote più avanti o divergente: sincronizza prima di push"
  if [ "$ahead" -eq 0 ]; then printf 'Niente da inviare.\n'; return; fi
  git_network push
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

tracked_file() {
  gitc ls-files --error-unmatch -- "$1" >/dev/null 2>&1
}

flake_preflight() {
  local hardware="hosts/$HOST/hardware-configuration.nix"
  [ -f "$REPO/flake.nix" ] || die "flake.nix mancante nel repo"
  [ -f "$REPO/flake.lock" ] || die "flake.lock mancante: genera e committa il lock prima di validare/applicare"
  tracked_file flake.lock || die "flake.lock presente ma non tracciato da Git"
  [ -f "$REPO/$hardware" ] || die "hardware-configuration.nix mancante per l'host $HOST"
  tracked_file "$hardware" || die "hardware-configuration.nix presente ma non tracciato da Git per l'host $HOST"
}

validate_config_raw() {
  flake_preflight
  need nix
  nix eval --no-update-lock-file --raw "$REPO#nixosConfigurations.$HOST.config.system.build.toplevel.drvPath" >/dev/null
}

validate_config() {
  validate_config_raw
  printf 'Validazione OK.\n'
}

build_config() {
  validate_config_raw
  nix build --no-update-lock-file --no-link "$REPO#nixosConfigurations.$HOST.config.system.build.toplevel"
  printf 'Build OK. Nessuna modifica applicata al sistema.\n'
}

prepare_apply_json() (
  local commit toplevel plan_json keep_pending=0

  trap '[ "$keep_pending" -eq 1 ] || rm -f -- "$PENDING_LINK"' EXIT
  trap 'exit 129' HUP
  trap 'exit 130' INT
  trap 'exit 143' TERM

  flake_preflight
  require_clean
  commit="$(head_sha)"
  validate_config_raw

  mkdir -p "$STATE_DIR"
  rm -f -- "$PENDING_LINK"

  toplevel="$(
    nix build \
      --no-update-lock-file \
      --out-link "$PENDING_LINK" \
      --print-out-paths \
      "$REPO#nixosConfigurations.$HOST.config.system.build.toplevel"
  )"

  [ -n "$toplevel" ] \
    || die "build del sistema non ha prodotto un toplevel"

  [ -x "$toplevel/bin/switch-to-configuration" ] \
    || die "switch-to-configuration non trovato nel toplevel"

  [ "$(head_sha)" = "$commit" ] \
    || die "HEAD cambiato durante la build: ripetere l'operazione"

  require_clean

  plan_json="$(
    jq -cn \
      --arg commit "$commit" \
      --arg toplevel "$toplevel" \
      '{commit:$commit,toplevel:$toplevel}'
  )"

  keep_pending=1
  printf '%s\n' "$plan_json"
)

record_applied() {
  local commit="$1" toplevel="$2" current
  case "$commit" in
    (*[!0-9a-f]*|'') die "commit applicato non valido" ;;
  esac
  [ "${#commit}" -eq 40 ] || die "commit applicato non valido"
  require_clean
  [ "$(head_sha)" = "$commit" ] || die "HEAD non coincide con il commit costruito"
  toplevel="$(readlink -f -- "$toplevel" 2>/dev/null || true)"
  current="$(current_system)"
  [ -n "$toplevel" ] && [ "$current" = "$toplevel" ] || die "il sistema corrente non coincide con il toplevel appena applicato"
  mkdir -p "$STATE_DIR"
  printf 'commit=%s\ntoplevel=%s\napplied_at=%s\n' \
    "$commit" "$toplevel" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$STATE_FILE"
  rm -f -- "$PENDING_LINK"
}

apply_config() (
  local plan commit toplevel activate_helper

  trap 'rm -f -- "$PENDING_LINK"' EXIT
  trap 'exit 129' HUP
  trap 'exit 130' INT
  trap 'exit 143' TERM

  plan="$(prepare_apply_json)"
  commit="$(printf '%s' "$plan" | jq -r .commit)"
  toplevel="$(printf '%s' "$plan" | jq -r .toplevel)"

  need sudo

  activate_helper="$(command -v kris-system-activate || true)"
  [ -n "$activate_helper" ] && [ -x "$activate_helper" ] \
    || die "kris-system-activate non disponibile"

  sudo -n -- "$activate_helper" "$toplevel"

  record_applied "$commit" "$toplevel"

  printf 'Applicata configurazione commit %s\n' "$commit"
)

cmd="${1:-}"
case "$cmd" in
  init)
    [ "$#" -le 2 ] || { usage >&2; exit 2; }
    need git
    [ ! -e "$REPO" ] || die "destinazione già esistente: $REPO"
    if [ "${KRISOS_NONINTERACTIVE:-0}" = 1 ]; then
      GIT_TERMINAL_PROMPT=0 timeout 45s git clone -- "${2:-$DEFAULT_REMOTE}" "$REPO"
    else
      git clone -- "${2:-$DEFAULT_REMOTE}" "$REPO"
    fi
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
  prepare-apply)
    [ "$#" -eq 2 ] && [ "$2" = --json ] || { usage >&2; exit 2; }
    need git; repo_ok; prepare_apply_json
    ;;
  record-applied)
    [ "$#" -eq 3 ] || { usage >&2; exit 2; }
    need git; repo_ok; record_applied "$2" "$3"
    ;;
  apply) [ "$#" -eq 1 ] || { usage >&2; exit 2; }; need git; repo_ok; apply_config ;;
  -h|--help|help|'') usage ;;
  *) usage >&2; exit 2 ;;
esac
