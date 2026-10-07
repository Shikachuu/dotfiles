#!/usr/bin/env bash
# mise config gate: deprecations -> what loads -> tasks -> lockfile -> gitignore -> doctor.
set -euo pipefail
shopt -s nullglob

if [ -t 1 ]; then
    RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
else
    RED=''; GREEN=''; YELLOW=''; BLUE=''; NC=''
fi

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

# Every project-level location mise reads, in precedence order. Missing one means
# the gate silently ignores a config mise actually loads.
CONFIGS=()
for f in \
    mise.local.toml .mise.local.toml mise.*.local.toml \
    mise.toml .mise.toml mise.*.toml .mise.*.toml \
    mise/config.toml \
    .mise/config.toml .mise/conf.d/*.toml \
    .config/mise.toml .config/mise/config.toml .config/mise/conf.d/*.toml
do
    [ -f "$f" ] && CONFIGS+=("$f")
done
if (( ${#CONFIGS[@]} == 0 )); then
    log_error "no mise config found in $DIR"
    exit 1
fi

# mise accepts most of these and only warns, so they look correct until removed.
section "Deprecated forms"
dep_hit=0
# Comments are stripped first so a config that quotes these rules in a comment
# does not trip the grep. sed keeps the line count, so line numbers stay right.
check_dep() {
    local pattern=$1 msg=$2 found=0 hits c
    for c in "${CONFIGS[@]}"; do
        if hits=$(sed 's/#.*//' "$c" | grep -nE "$pattern"); then
            printf '%s\n' "$hits" | sed "s|^|    $c:|"
            found=1
        fi
    done
    if (( found )); then fail "$msg"; dep_hit=1; fi
    return 0
}
check_dep '^\[alias(\.|\])'                   'use [tool_alias] or [shell_alias], not [alias]'
check_dep '^[[:space:]]*(env_file|dotenv|env_path)[[:space:]]*=' 'use [env] _.file / _.path, not top-level env_file/dotenv/env_path'
check_dep '_\.venv[[:space:]]*='              'use [env] _.python.venv, not _.venv'
check_dep '\{\{[[:space:]]*(arg|option|flag)\(' 'use the usage field for task args, not the Tera arg()/option()/flag() helpers'
check_dep '(^[[:space:]]*"?|=[[:space:]]*"?)ubi:' 'ubi is deprecated upstream; prefer aqua or github'
if (( dep_hit == 0 )); then
    log_success "no deprecated forms"
    SUMMARY+=("deprecations: clean")
else
    SUMMARY+=("deprecations: FOUND")
fi

section "Configs that actually load"
if mise config ls; then
    SUMMARY+=("config: ${#CONFIGS[@]} project file(s), parsed")
else
    fail "mise could not parse the config; fix the errors above before trusting anything below"
    SUMMARY+=("config: PARSE FAILED")
fi
IS_GIT=0
git rev-parse --git-dir >/dev/null 2>&1 && IS_GIT=1
for c in "${CONFIGS[@]}"; do
    case "$c" in
        *local.toml)
            if (( IS_GIT )) && git ls-files --error-unmatch "$c" >/dev/null 2>&1; then
                fail "$c is committed; a local override outranks mise.toml for the whole team"
            fi
            ;;
    esac
done

section "Resolved tool versions"
if mise ls --current; then
    SUMMARY+=("tools: resolved")
else
    fail "could not resolve tool versions"
    SUMMARY+=("tools: UNRESOLVED")
fi

section "Tasks"
mise tasks ls || true
if mise tasks validate; then
    SUMMARY+=("tasks: valid")
else
    fail "mise tasks validate reported errors"
    SUMMARY+=("tasks: INVALID")
fi
while IFS= read -r t; do
    [ -n "$t" ] || continue
    d=$(mise tasks info "$t" --json 2>/dev/null | jq -r '.description // ""')
    [ -n "$d" ] || log_warn "task '$t' has no description"
done < <(mise tasks ls --name-only 2>/dev/null)

# mise omits a non-executable file task from `mise tasks ls` entirely; only
# `mise run <name>` explains why. Docs and sourced helpers are not tasks, so skip
# them rather than failing a valid layout.
for d in mise-tasks .mise-tasks mise/tasks .mise/tasks .config/mise/tasks; do
    [ -d "$d" ] || continue
    while IFS= read -r -d '' f; do
        case "${f##*/}" in .*|*.md|*.txt|LICENSE*) continue ;; esac
        case "$f" in */lib/*|*/_lib/*|*/.*/*) continue ;; esac
        [ -x "$f" ] && continue
        # Only a file that means to be a task: docs and sourced helpers have no shebang.
        head -c 2 "$f" 2>/dev/null | grep -q '#!' \
            && fail "$f has a shebang but is not executable, so mise will not discover it (chmod +x)"
    done < <(find "$d" -type f -print0 2>/dev/null)
done

section "Lockfile"
if grep -qE '^[[:space:]]*lockfile[[:space:]]*=[[:space:]]*true' "${CONFIGS[@]}" 2>/dev/null; then
    log_warn "settings.lockfile = true adds a trust prompt and is not needed once mise.lock is committed"
fi
if [ -f mise.lock ]; then
    if grep -q 'lockfile_version\|^\[\[tools\.' mise.lock; then
        log_success "mise.lock present"
    else
        fail "mise.lock exists but has no lockfile_version or [[tools.*]]; it looks corrupt, regenerate with: mise lock"
    fi
    if (( IS_GIT )) && ! git ls-files --error-unmatch mise.lock >/dev/null 2>&1; then
        fail "mise.lock is not tracked by git; commit it"
    fi
    if [ -n "${MISE_OFFLINE:-}" ]; then
        log_info "MISE_OFFLINE set, skipping the drift check"
    else
        mise lock --dry-run || log_warn "mise lock --dry-run reported drift (or could not reach the network)"
    fi
    SUMMARY+=("lockfile: present")
else
    fail "no mise.lock; run: mise lock, then commit it"
    SUMMARY+=("lockfile: MISSING")
fi

section "gitignore"
if (( IS_GIT )); then
    if git check-ignore -q mise.lock 2>/dev/null; then
        fail "mise.lock is gitignored; it must be committed"
    else
        log_success "mise.lock is not ignored"
    fi
    for pat in mise.local.toml mise.dev.local.toml .env; do
        git check-ignore -q "$pat" 2>/dev/null || log_warn "$pat is not gitignored"
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
