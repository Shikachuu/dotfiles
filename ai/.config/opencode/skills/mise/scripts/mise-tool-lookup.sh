#!/usr/bin/env bash
# Resolve a tool name to its mise backend and a real latest version.
# Prints the [tools] line to paste into mise.toml. Never guesses.
# Exits non-zero if any name could not be resolved, so a caller can branch on it.
set -euo pipefail

for c in mise jq; do
    command -v "$c" >/dev/null || { echo "missing: $c" >&2; exit 1; }
done
[ $# -ge 1 ] || { echo "usage: $0 <name> [<name>...]" >&2; exit 2; }

# Backend preference, best first. Unlisted backends sort last.
# core is built in, aqua verifies signatures, asdf runs arbitrary shell at install.
PREF="core aqua github gitlab forgejo npm cargo pipx go gem dotnet spm conda http s3 pkgx vfox asdf"

# Source of truth for what this mise build actually supports. The docs list
# backends that are not compiled in (packslip) and mark others deprecated (ubi).
AVAILABLE=" $(mise backends ls | tr '\n' ' ') "
# Canonical names only: `rg` and `ripgrep` are both registry rows, but only
# `ripgrep` survives --hide-aliased.
CANON=$(mise registry --hide-aliased 2>/dev/null || true)

FAILED=0

# A calver tool like yt-dlp 2026.08.19 must not be pinned to "2026", which would
# float across the whole year. Pin those exactly.
MINOR_MATTERS=" python go ruby rust elixir erlang zig dotnet jq perl swift "
suggest_pin() {
    local v=$1 name=$2 major=${1%%.*}
    if [[ $major =~ ^[0-9]{4}$ ]] && (( major >= 2000 )); then
        printf '%s' "$v"                       # calver: a major is a whole year
    elif [ "$major" = "0" ]; then
        printf '%s' "${v%.*}"                  # 0.x: every minor is a breaking change
    elif [[ $MINOR_MATTERS == *" $name "* ]]; then
        printf '%s' "${v%.*}"                  # major.minor
    else
        printf '%s' "$major"
    fi
}

canonical_name() {
    local name=$1 specs=$2 row
    # Already canonical?
    if printf '%s\n' "$CANON" | awk -v n="$name" '$1==n{found=1} END{exit !found}'; then
        printf '%s' "$name"; return
    fi
    row=$(printf '%s\n' "$CANON" | awk -v s="$specs" '{ $1=$1; name=$1; sub(/^[^ ]+ +/,""); if ($0==s) { print name; exit } }')
    printf '%s' "${row:-$name}"
}

lookup_one() {
    local name=$1 json short desc aliases first best="" bver line specs canon
    if [ -z "$name" ]; then
        echo "empty tool name" >&2; FAILED=1; return 0
    fi
    if [[ $name == *:* ]]; then
        echo "$name already carries a backend prefix; look up the bare name instead (${name##*/})"
        echo
        return 0
    fi
    if ! json=$(mise registry --json "$name" 2>/dev/null); then
        echo "$name: no exact match in the registry"
        local hits
        hits=$(mise search -m contains "$name" 2>/dev/null | head -8 || true)
        if [ -n "$hits" ]; then
            echo "  closest names (re-run this script on the one you want):"
            printf '%s\n' "$hits" | sed 's/^/    /'
        else
            echo "  no fuzzy matches either; the tool may need an explicit backend spec"
        fi
        echo
        FAILED=1
        return 0
    fi

    short=$(printf '%s' "$json" | jq -r '.short')
    desc=$(printf '%s' "$json" | jq -r '.description // ""')
    aliases=$(printf '%s' "$json" | jq -r '(.aliases // []) | join(", ")')
    first=$(printf '%s' "$json" | jq -r '.backends[0]')
    specs=$(printf '%s' "$json" | jq -r '.backends | join(" ")')
    canon=$(canonical_name "$short" "$specs")

    for p in $PREF; do
        case "$AVAILABLE" in *" $p "*) ;; *) continue ;; esac
        while IFS= read -r b; do
            [ "${b%%:*}" = "$p" ] && { best=$b; break 2; }
        done < <(printf '%s' "$json" | jq -r '.backends[]')
    done
    [ -n "$best" ] || best=$first

    # Resolve against the backend we are about to recommend, not the default.
    if [ "$best" = "$first" ]; then
        bver=$(mise latest "$canon" 2>/dev/null || echo "")
    else
        bver=$(mise latest "$best" 2>/dev/null || mise latest "$canon" 2>/dev/null || echo "")
    fi

    echo "$canon${desc:+  - $desc}"
    [ "$canon" != "$short" ] && echo "  note: '$short' is an alias; '$canon' is the canonical name"
    [ -n "$aliases" ] && echo "  aliases:  $aliases"
    echo "  backends: $specs"
    echo "  registry default: $first"
    echo "  preferred:        $best"

    if [ -z "$bver" ]; then
        echo "  latest:   UNRESOLVED (mise latest returned nothing; check the network or pin by hand)"
        echo
        FAILED=1
        return 0
    fi

    # A bare shorthand resolves to the registry's FIRST backend. Only write the
    # shorthand when that is also the one we want.
    if [ "$best" = "$first" ]; then
        line="$canon = \"$(suggest_pin "$bver" "$canon")\""
    else
        line="\"$best\" = \"$(suggest_pin "$bver" "$canon")\""
        echo "  note: the registry default is not the preferred backend, so pin it explicitly"
    fi
    echo "  latest:   $bver"
    echo "  [tools]   $line"
    echo
}

for n in "$@"; do lookup_one "$n"; done
exit "$FAILED"
