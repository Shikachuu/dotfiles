#!/usr/bin/env bash
# mise config gate: what loads -> deprecations -> tasks -> lockfile -> gitignore -> doctor.
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1" >&2; }
section()     { echo; echo -e "${BLUE}==>${NC} ${1}"; }

command -v mise >/dev/null || { log_error "mise not found"; exit 1; }
command -v jq   >/dev/null || { log_error "jq not found"; exit 1; }

DIR="${1:-$PWD}"
[ -d "$DIR" ] || { log_error "not a directory: $DIR"; exit 1; }
DIR="$(cd "$DIR" && pwd)"
cd "$DIR"

SUMMARY=()
FAILED=0
fail() { log_error "$1"; FAILED=1; }

# Project configs that belong to this repo. Parent and global configs are out of
# scope: this gate checks what the repo ships, not the machine it runs on.
CONFIGS=()
for f in mise.toml .mise.toml mise.*.toml .mise/config.toml .config/mise/config.toml .config/mise.toml; do
    [ -f "$f" ] && CONFIGS+=("$f")
done
if (( ${#CONFIGS[@]} == 0 )); then
    log_error "no mise config found in $DIR"
    exit 1
fi

# mise accepts all of these today and warns, or silently plans removal. None are
# reported by any mise subcommand, so grep is the only check available.
section "Deprecated forms"
dep_hit=0
check_dep() {
    local pattern=$1 msg=$2 hits
    if hits=$(grep -nE "$pattern" "${CONFIGS[@]}" 2>/dev/null); then
        printf '%s\n' "$hits" | sed 's/^/    /'
        fail "$msg"
        dep_hit=1
    fi
}
check_dep '^\[alias\]'                        'use [tool_alias] or [shell_alias], not [alias]'
check_dep '^[[:space:]]*(env_file|dotenv|env_path)[[:space:]]*='  'use [env] _.file / _.path, not top-level env_file/dotenv/env_path'
check_dep '_\.venv'                           'use [env] _.python.venv, not _.venv'
check_dep '\{\{[[:space:]]*(arg|option|flag)\(' 'use the usage field for task args, not the Tera arg()/option()/flag() helpers'
check_dep '(^|["[:space:]])ubi:'              'ubi is deprecated upstream; prefer aqua or github'
if (( dep_hit == 0 )); then
    log_success "no deprecated forms"
    SUMMARY+=("deprecations: clean")
else
    SUMMARY+=("deprecations: FOUND")
fi

section "Configs that actually load"
mise config ls || log_warn "mise could not list configs; see errors above"
for c in "${CONFIGS[@]}"; do
    case "$c" in
        *.local.toml)
            if git -C "$DIR" ls-files --error-unmatch "$c" >/dev/null 2>&1; then
                fail "$c is committed; a local override outranks mise.toml for the whole team"
            fi
            ;;
    esac
done
SUMMARY+=("config: ${#CONFIGS[@]} project file(s) found")

section "Resolved tool versions"
mise ls --current || true
SUMMARY+=("tools: resolved")

section "Tasks"
mise tasks ls || true
if mise tasks validate 2>&1; then
    SUMMARY+=("tasks: valid")
else
    fail "mise tasks validate reported errors"
    SUMMARY+=("tasks: INVALID")
fi
# mise does not require a description, but `mise tasks ls` is the discovery path.
while IFS= read -r t; do
    [ -n "$t" ] || continue
    d=$(mise tasks info "$t" --json 2>/dev/null | jq -r '.description // ""')
    [ -n "$d" ] || log_warn "task '$t' has no description"
done < <(mise tasks ls --no-header 2>/dev/null | awk '{print $1}')

# mise omits a non-executable file task from `mise tasks ls` entirely; only
# `mise run <name>` explains why. Catch it here instead.
for d in mise-tasks .mise-tasks mise/tasks .mise/tasks .config/mise/tasks; do
    [ -d "$d" ] || continue
    while IFS= read -r -d '' f; do
        [ -x "$f" ] || fail "$f is not executable, so mise will not discover it (chmod +x)"
    done < <(find "$d" -type f ! -name '.*' -print0 2>/dev/null)
done

section "Lockfile"
lock_setting=$(mise settings get lockfile 2>/dev/null || echo "unset")
if [ "$lock_setting" = "true" ]; then
    log_warn "settings.lockfile = true adds a trust prompt and is not needed once mise.lock is committed"
fi
if [ -f mise.lock ]; then
    log_success "mise.lock present"
    mise lock --dry-run || log_warn "mise lock --dry-run reported drift"
    SUMMARY+=("lockfile: present")
else
    fail "no mise.lock; run: mise lock, then commit it"
    SUMMARY+=("lockfile: MISSING")
fi

section "gitignore"
if git -C "$DIR" rev-parse --git-dir >/dev/null 2>&1; then
    if git -C "$DIR" check-ignore -q mise.lock 2>/dev/null; then
        fail "mise.lock is gitignored; it must be committed"
    else
        log_success "mise.lock is not ignored"
    fi
    for f in mise.local.toml .env; do
        git -C "$DIR" check-ignore -q "$f" 2>/dev/null \
            || log_warn "$f is not gitignored"
    done
    SUMMARY+=("gitignore: checked")
else
    log_warn "not a git repo, skipping gitignore checks"
    SUMMARY+=("gitignore: skipped")
fi

# Warn-only: doctor reports machine facts that are not this repo's problem.
section "Trust and doctor"
mise trust --show || true
mise doctor >/dev/null 2>&1 || log_warn "mise doctor reported problems; run it directly for detail"
SUMMARY+=("doctor: advisory only")

section "Summary"
for line in "${SUMMARY[@]}"; do log_info "$line"; done
if (( FAILED )); then
    log_error "validation failed for $DIR"
    exit 1
fi
log_success "all checks passed for $DIR"
