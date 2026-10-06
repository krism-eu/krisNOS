set -euo pipefail

REPO="${KRISOS_CONFIG_REPO:-$HOME/krisNOS-config}"
HOST="${KRISOS_HOST:-}"
if [ -z "$HOST" ]; then
  HOST="$(cut -d. -f1 </proc/sys/kernel/hostname)"
  if [ ! -f "$REPO/hosts/$HOST/configuration.nix" ] && [ -d "$REPO/hosts" ]; then
    candidate=""
    count=0
    for candidate_path in "$REPO"/hosts/*/configuration.nix; do
      [ -f "$candidate_path" ] || continue
      candidate="$(basename "$(dirname "$candidate_path")")"
      count=$((count + 1))
    done
    if [ "$count" -eq 1 ]; then
      HOST="$candidate"
    fi
  fi
fi
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/krisos"
STATE_FILE="$STATE_DIR/config-sync.state"
PENDING_LINK="$STATE_DIR/pending-system"
SUDO=/run/wrappers/bin/sudo
MANAGED_REL=modules/krisncc-managed.nix
PACKAGES_BEGIN='# krisNCC system packages: begin'
PACKAGES_END='# krisNCC system packages: end'

usage() {
  cat <<'USAGE'
Usage:
  kris-configctl init
  kris-configctl status [--json]
  kris-configctl fetch
  kris-configctl diff
  kris-configctl pull
  kris-configctl push
  kris-configctl sync
  kris-configctl validate
  kris-configctl build
  kris-configctl apply
  kris-configctl system-packages [--json]
  kris-configctl system-package-add [--unfree] <nixpkgs-attribute>
  kris-configctl system-package-remove <nixpkgs-attribute>
  kris-configctl cleanup-status [--json]
  kris-configctl cleanup-profile
  kris-configctl cleanup-system
  kris-configctl cleanup-store

Internal krisNCC commands:
  kris-configctl prepare-apply --json
  kris-configctl record-applied <commit> <toplevel>

Environment:
  KRISOS_CONFIG_REPO     local working tree (default: ~/krisNOS-config)
  KRISOS_HOST            NixOS flake host name (default: current hostname; if
                         it does not match and the repo has exactly one host,
                         that sole host is selected automatically)
  KRISOS_NONINTERACTIVE  when 1, network Git operations cannot prompt and time out

Safety rules:
- synchronization is never automatic;
- never force-pushes or auto-merges diverged histories;
- never overwrites a dirty working tree;
- pull is fast-forward only;
- validate/build/apply refuse lock-file updates;
- build validates first and does not need root;
- system package changes touch only krisncc-managed.nix, validate, create one
  local commit, then build and switch; GitHub sync remains separate/manual;
- cleanup is always explicit: app-profile history older than 30 days, system
  generations beyond the last 5, and unreachable store paths are separate actions.
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
  local commit="$1" toplevel="$2" current current_head="" dirty=""
  case "$commit" in
    (*[!0-9a-f]*|'') die "commit applicato non valido" ;;
  esac
  [ "${#commit}" -eq 40 ] || die "commit applicato non valido"

  toplevel="$(readlink -f -- "$toplevel" 2>/dev/null || true)"
  current="$(current_system)"
  [ -n "$toplevel" ] && [ "$current" = "$toplevel" ] \
    || die "il sistema corrente non coincide con il toplevel appena applicato"

  if [ -d "$REPO/.git" ]; then
    current_head="$(head_sha 2>/dev/null || true)"
    dirty="$(dirty_flag 2>/dev/null || true)"
    if [ -n "$current_head" ] && [ "$current_head" != "$commit" ]; then
      printf 'kris-configctl: avviso: HEAD è cambiato dopo la build; registro comunque il commit applicato %s\n' \
        "$commit" >&2
    fi
    if [ "$dirty" = true ]; then
      printf '%s\n' 'kris-configctl: avviso: working tree modificato dopo la build; il toplevel applicato resta registrato.' >&2
    fi
  else
    printf '%s\n' 'kris-configctl: avviso: repo non disponibile dopo lo switch; registro il toplevel applicato verificato.' >&2
  fi

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

  [ -x "$SUDO" ] || die "wrapper sudo NixOS non disponibile: $SUDO"

  activate_helper="$(command -v kris-system-activate || true)"
  [ -n "$activate_helper" ] && [ -x "$activate_helper" ] \
    || die "kris-system-activate non disponibile"

  "$SUDO" -n -- "$activate_helper" "$toplevel"

  record_applied "$commit" "$toplevel"

  printf 'Applicata configurazione commit %s\n' "$commit"
)

valid_system_attr() {
  case "$1" in
    (*[!A-Za-z0-9._+@-]*|'') return 1 ;;
    (-*|.*|*..*|*.) return 1 ;;
    (*) return 0 ;;
  esac
}

managed_file() {
  printf '%s/%s\n' "$REPO" "$MANAGED_REL"
}

check_managed_markers() {
  local file
  file="$(managed_file)"
  [ -f "$file" ] || die "$MANAGED_REL mancante"
  tracked_file "$MANAGED_REL" || die "$MANAGED_REL non è tracciato da Git"
  [ "$(grep -Fc "$PACKAGES_BEGIN" "$file")" -eq 1 ] \
    || die "marcatore iniziale pacchetti krisNCC mancante o duplicato"
  [ "$(grep -Fc "$PACKAGES_END" "$file")" -eq 1 ] \
    || die "marcatore finale pacchetti krisNCC mancante o duplicato"
}

managed_package_lines() {
  local file
  file="$(managed_file)"
  check_managed_markers
  awk -v begin="$PACKAGES_BEGIN" -v end="$PACKAGES_END" '
    index($0, begin) { inside=1; next }
    index($0, end) { inside=0; next }
    inside {
      line=$0
      sub(/^[[:space:]]*"/, "", line)
      sub(/"[[:space:]]*$/, "", line)
      if (line != $0 && line != "") print line
    }
  ' "$file"
}

system_packages_json() {
  need jq
  managed_package_lines | jq -Rsc 'split("\n") | map(select(length > 0))'
}

rewrite_managed_packages() {
  local action="$1" attr="$2" allow_unfree="$3"
  local file list tmp next
  file="$(managed_file)"
  check_managed_markers
  list="$(mktemp)"
  tmp="$(mktemp)"
  next="$(mktemp)"

  managed_package_lines > "$list"
  case "$action" in
    add)
      if grep -Fxq -- "$attr" "$list"; then
        rm -f -- "$list" "$tmp" "$next"
        return 3
      fi
      printf '%s\n' "$attr" >> "$list"
      sort -u -o "$list" "$list"
      ;;
    remove)
      if ! grep -Fxq -- "$attr" "$list"; then
        rm -f -- "$list" "$tmp" "$next"
        return 4
      fi
      grep -Fxv -- "$attr" "$list" > "$next" || true
      mv -- "$next" "$list"
      ;;
    *)
      rm -f -- "$list" "$tmp" "$next"
      die "azione pacchetto sistema non valida"
      ;;
  esac

  awk -v begin="$PACKAGES_BEGIN" -v end="$PACKAGES_END" -v list="$list" '
    index($0, begin) {
      print
      while ((getline package < list) > 0)
        print "    \"" package "\""
      close(list)
      inside=1
      next
    }
    index($0, end) { inside=0; print; next }
    !inside { print }
  ' "$file" > "$tmp"
  mv -- "$tmp" "$file"

  if [ "$allow_unfree" = 1 ]; then
    if grep -Fqx '  krisos.allowUnfreeSystemPackages = false;' "$file"; then
      sed -i 's/^  krisos\.allowUnfreeSystemPackages = false;$/  krisos.allowUnfreeSystemPackages = true;/' "$file"
    elif ! grep -Fqx '  krisos.allowUnfreeSystemPackages = true;' "$file"; then
      rm -f -- "$list" "$next"
      die "opzione allowUnfreeSystemPackages mancante nel file gestito"
    fi
  fi

  rm -f -- "$list" "$next"
}

managed_system_package_apply() (
  local action="$1" attr="$2" allow_unfree="$3" result committed=0 verb
  need git
  repo_ok
  require_clean
  flake_preflight
  valid_system_attr "$attr" || die "attributo nixpkgs non valido: $attr"
  check_managed_markers

  trap 'if [ "$committed" -eq 0 ]; then gitc restore --staged -- "$MANAGED_REL" >/dev/null 2>&1 || true; gitc restore -- "$MANAGED_REL" >/dev/null 2>&1 || true; fi' EXIT

  set +e
  rewrite_managed_packages "$action" "$attr" "$allow_unfree"
  result=$?
  set -e
  if [ "$result" -eq 3 ]; then
    printf 'Il pacchetto %s è già nel sistema.\n' "$attr"
    exit 0
  fi
  if [ "$result" -eq 4 ]; then
    printf 'Il pacchetto %s non è presente nel sistema.\n' "$attr"
    exit 0
  fi
  [ "$result" -eq 0 ] || exit "$result"

  gitc diff --check -- "$MANAGED_REL"
  validate_config_raw
  gitc add -- "$MANAGED_REL"

  if [ "$action" = add ]; then verb=add; else verb=remove; fi
  gitc \
    -c user.name='krisNCC' \
    -c user.email='krisncc@localhost' \
    -c commit.gpgSign=false \
    commit -m "krisNCC: $verb system package $attr" -- "$MANAGED_REL" >/dev/null
  committed=1

  printf 'Configurazione aggiornata localmente per %s; build e switch in corso.\n' "$attr"
  apply_config
)

cleanup_status_json() {
  local system_generations profile_generations used_kib free_kib
  need jq
  need nix-env
  need nix
  system_generations="$(nix-env --list-generations --profile /nix/var/nix/profiles/system 2>/dev/null | awk 'NF { n++ } END { print n + 0 }')"
  profile_generations="$(nix profile history 2>/dev/null | awk '/^Version[[:space:]]+[0-9]+/ { n++ } END { print n + 0 }')"
  read -r used_kib free_kib < <(df -Pk /nix | awk 'NR == 2 { print $3, $4 }')
  used_kib="${used_kib:-0}"
  free_kib="${free_kib:-0}"
  jq -cn \
    --argjson systemGenerations "$system_generations" \
    --argjson profileGenerations "$profile_generations" \
    --argjson storeUsedMiB "$((used_kib / 1024))" \
    --argjson storeFreeMiB "$((free_kib / 1024))" \
    '{schema:1,systemGenerations:$systemGenerations,profileGenerations:$profileGenerations,storeUsedMiB:$storeUsedMiB,storeFreeMiB:$storeFreeMiB}'
}

cleanup_profile() {
  need nix
  nix profile wipe-history --older-than 30d
  printf 'Cronologia del profilo app più vecchia di 30 giorni rimossa.\n'
}

cleanup_system() {
  local nix_env
  need nix-env
  [ -x "$SUDO" ] || die "wrapper sudo NixOS non disponibile: $SUDO"
  nix_env="$(command -v nix-env)"
  "$SUDO" -n -- "$nix_env" --profile /nix/var/nix/profiles/system --delete-generations +5
  printf 'Generazioni di sistema ridotte mantenendo le ultime 5 rispetto alla generazione corrente.\n'
}

cleanup_store() {
  local nix_store
  need nix-store
  [ -x "$SUDO" ] || die "wrapper sudo NixOS non disponibile: $SUDO"
  nix_store="$(command -v nix-store)"
  "$SUDO" -n -- "$nix_store" --gc
  printf 'Garbage collection completata: rimossi solo path dello store non più raggiungibili.\n'
}

cmd="${1:-}"
case "$cmd" in
  init)
    [ "$#" -eq 1 ] || { usage >&2; exit 2; }
    need git
    [ -d "$REPO" ] || die "configurazione locale mancante: $REPO"
    [ -f "$REPO/flake.nix" ] || die "flake.nix mancante nella configurazione locale"

    if [ -d "$REPO/.git" ]; then
      printf 'Repo locale già inizializzato: %s\n' "$REPO"
      exit 0
    fi

    git -C "$REPO" init -b main >/dev/null
    git -C "$REPO" add --all
    git -C "$REPO"       -c user.name='krisNOS local'       -c user.email='local@localhost'       commit -m 'Initial local krisNOS configuration' >/dev/null

    printf 'Repo locale inizializzato: %s\n' "$REPO"
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
    record_applied "$2" "$3"
    ;;
  apply) [ "$#" -eq 1 ] || { usage >&2; exit 2; }; need git; repo_ok; apply_config ;;
  system-packages)
    [ "$#" -le 2 ] || { usage >&2; exit 2; }
    need git; repo_ok
    if [ "${2:-}" = --json ]; then system_packages_json; else managed_package_lines; fi
    ;;
  system-package-add)
    shift
    allow_unfree=0
    if [ "${1:-}" = --unfree ]; then allow_unfree=1; shift; fi
    [ "$#" -eq 1 ] || { usage >&2; exit 2; }
    managed_system_package_apply add "$1" "$allow_unfree"
    ;;
  system-package-remove)
    [ "$#" -eq 2 ] || { usage >&2; exit 2; }
    managed_system_package_apply remove "$2" 0
    ;;
  cleanup-status)
    [ "$#" -le 2 ] || { usage >&2; exit 2; }
    if [ "${2:-}" = --json ]; then cleanup_status_json; else cleanup_status_json | jq .; fi
    ;;
  cleanup-profile) [ "$#" -eq 1 ] || { usage >&2; exit 2; }; cleanup_profile ;;
  cleanup-system) [ "$#" -eq 1 ] || { usage >&2; exit 2; }; cleanup_system ;;
  cleanup-store) [ "$#" -eq 1 ] || { usage >&2; exit 2; }; cleanup_store ;;
  -h|--help|help|'') usage ;;
  *) usage >&2; exit 2 ;;
esac
