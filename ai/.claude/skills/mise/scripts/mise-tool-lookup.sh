#!/usr/bin/env bash
# Resolve a tool name to its mise backend and a real latest version.
# Prints the [tools] line to paste into mise.toml. Never guesses.
set -euo pipefail

for c in mise jq; do
    command -v "$c" >/dev/null || { echo "missing: $c" >&2; exit 1; }
done
[ $# -ge 1 ] || { echo "usage: $0 <name> [<name>...]" >&2; exit 2; }

# Backend preference, best first. Unlisted backends sort last.
# core is built in, aqua verifies signatures, asdf runs arbitrary shell at install.
PREF="core aqua github gitlab forgejo npm cargo pipx go gem dotnet spm conda http s3 ubi pkgx vfox asdf"

# Source of truth for what this mise build actually supports. The docs list
# backends that are not compiled in (packslip) and mark others deprecated (ubi).
AVAILABLE=" $(mise backends ls | tr '\n' ' ') "

lookup_one() {
    local name=$1 json short desc aliases first best="" bver line
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
        return 0
    fi

    short=$(printf '%s' "$json" | jq -r '.short')
    desc=$(printf '%s' "$json" | jq -r '.description // ""')
    aliases=$(printf '%s' "$json" | jq -r '(.aliases // []) | join(", ")')
    first=$(printf '%s' "$json" | jq -r '.backends[0]')

    # Walk the preference order, take the first backend this build supports.
    for p in $PREF; do
        case "$AVAILABLE" in *" $p "*) ;; *) continue ;; esac
        while IFS= read -r b; do
            [ "${b%%:*}" = "$p" ] && { best=$b; break 2; }
        done < <(printf '%s' "$json" | jq -r '.backends[]')
    done
    [ -n "$best" ] || best=$first

    bver=$(mise latest "$short" 2>/dev/null || echo "")

    echo "$short${desc:+  - $desc}"
    [ -n "$aliases" ] && echo "  aliases:  $aliases"
    echo "  backends: $(printf '%s' "$json" | jq -r '.backends | join(" ")')"
    echo "  registry default: $first"
    echo "  preferred:        $best"

    # A bare shorthand resolves to the registry's FIRST backend. Only write the
    # shorthand when that is also the one we want.
    if [ "$best" = "$first" ]; then
        line="$short = \"${bver%%.*}\""
        [ -n "$bver" ] || line="$short = \"<version>\""
    else
        line="\"$best\" = \"${bver%%.*}\""
        [ -n "$bver" ] || line="\"$best\" = \"<version>\""
        echo "  note: the registry default is not the preferred backend, so pin it explicitly"
    fi
    echo "  latest:   ${bver:-unknown}"
    echo "  [tools]   $line"
    echo
}

for n in "$@"; do lookup_one "$n"; done
