#!/usr/bin/env bash
# Generic OpenTofu validation gate: docs -> fmt -> tflint -> trivy -> test -> validate.
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

# Default: a `tofu/` dir next to this script's parent, else the current dir.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -n "${1:-}" ]]; then
    TOFU_DIR="$1"
elif [[ -d "$SCRIPT_DIR/../tofu" ]]; then
    TOFU_DIR="$SCRIPT_DIR/../tofu"
else
    TOFU_DIR="$PWD"
fi
if [[ ! -d "$TOFU_DIR" ]]; then
    log_error "Tofu dir not found: $TOFU_DIR"
    exit 1
fi
TOFU_DIR="$(cd "$TOFU_DIR" && pwd)"

REQUIRED_TOOLS=(tofu terraform-docs tflint trivy)
missing=()
for t in "${REQUIRED_TOOLS[@]}"; do
    command -v "$t" >/dev/null 2>&1 || missing+=("$t")
done
if (( ${#missing[@]} > 0 )); then
    log_error "Missing required tool(s): ${missing[*]}"
    log_error "Install all of the following before running: ${REQUIRED_TOOLS[*]}"
    exit 1
fi

# If an environment/ dir exists, treat each subdir as an env; otherwise the
# tofu root itself is the single validation target.
ENV_DIRS=()
if [[ -d "$TOFU_DIR/environment" ]]; then
    while IFS= read -r -d '' d; do ENV_DIRS+=("$d"); done \
        < <(find "$TOFU_DIR/environment" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)
fi
if (( ${#ENV_DIRS[@]} == 0 )); then
    ENV_DIRS=("$TOFU_DIR")
    HAS_ENV_LAYOUT=false
else
    HAS_ENV_LAYOUT=true
fi

SUMMARY=()

section "Generating Terraform docs"
for d in "${ENV_DIRS[@]}"; do
    log_info "Docs for $d"
    docs_args=(md table "$d"
        --output-file README.md
        --output-mode inject
        --show inputs
        --show modules
        --recursive
        --hide-empty)
    # Only point recursion at a modules/ dir when the env layout implies one.
    if $HAS_ENV_LAYOUT && [[ -d "$TOFU_DIR/modules" ]]; then
        docs_args+=(--recursive-path ../../modules)
    fi
    terraform-docs "${docs_args[@]}"
    terraform-docs tfvars hcl "$d" > "$d/example.tfvars"
done
SUMMARY+=("terraform-docs: regenerated README + example.tfvars for ${#ENV_DIRS[@]} target(s)")

section "Checking formatting (tofu fmt)"
tofu fmt -check -recursive "$TOFU_DIR"
SUMMARY+=("tofu fmt: clean")

section "Linting (tflint)"
tflint --init --chdir "$TOFU_DIR"
tflint --recursive --chdir "$TOFU_DIR" --format=compact --color --minimum-failure-severity=warning
SUMMARY+=("tflint: passed")

section "Security scan (trivy)"
trivy_args=(fs --scanners secret,misconfig,vuln --disable-telemetry --exit-code 1
    --skip-files '**/terraform.tfvars')
if [[ -f "$TOFU_DIR/.trivyignore.yaml" ]]; then
    trivy_args+=(--ignorefile "$TOFU_DIR/.trivyignore.yaml")
fi
trivy "${trivy_args[@]}" "$TOFU_DIR"
SUMMARY+=("trivy: no findings (secret,misconfig,vuln)")

# Discover *.tofutest.hcl / *.tftest.hcl; run `tofu test` once per dir. Skipped
# entirely when none exist.
section "Mock tests (tofu test)"
TEST_DIRS=()
while IFS= read -r -d '' f; do
    TEST_DIRS+=("$(dirname "$f")")
done < <(find "$TOFU_DIR" -type f \( -name '*.tofutest.hcl' -o -name '*.tftest.hcl' \) -print0 2>/dev/null | sort -z)
if (( ${#TEST_DIRS[@]} > 0 )); then
    mapfile -t TEST_DIRS < <(printf '%s\n' "${TEST_DIRS[@]}" | sort -u)
fi
if (( ${#TEST_DIRS[@]} == 0 )); then
    log_warn "No *.tofutest.hcl / *.tftest.hcl files found - skipping tofu test"
    SUMMARY+=("tofu test: skipped (no test files)")
else
    for d in "${TEST_DIRS[@]}"; do
        log_info "Running tofu test in $d"
        (cd "$d" && tofu init -input=false -backend=false >/dev/null && tofu test)
    done
    SUMMARY+=("tofu test: passed in ${#TEST_DIRS[@]} dir(s)")
fi

section "Validating (tofu validate)"
for d in "${ENV_DIRS[@]}"; do
    name="$(basename "$d")"
    log_info "Validating $name"
    (cd "$d" && tofu init -input=false -backend=false >/dev/null && tofu validate)
done
SUMMARY+=("tofu validate: passed for ${#ENV_DIRS[@]} target(s)")

section "Summary"
for line in "${SUMMARY[@]}"; do
    log_success "$line"
done
log_success "All validation steps passed for $TOFU_DIR"
