#!/bin/bash

set -euo pipefail

ARCHIFY_TAG=v3.2.0
ARCHIFY_COMMIT=208acba8d412335185b2056fedf54b3405df43fb
ARCHIFY_REPO=https://github.com/tt-a1i/archify

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SRC="${XDG_DATA_HOME:-$HOME/.local/share}/archify"
LINK="$DOTFILES_DIR/ai/.claude/skills/archify"

if [[ ! -d $SRC/.git ]]; then
  git clone --quiet --depth 1 --filter=blob:none --sparse --no-checkout "$ARCHIFY_REPO" "$SRC"
fi
git -C "$SRC" sparse-checkout set --no-cone /archify/
git -C "$SRC" cat-file -e "$ARCHIFY_COMMIT^{commit}" 2>/dev/null ||
  git -C "$SRC" fetch --quiet --depth 1 origin "$ARCHIFY_COMMIT"
git -C "$SRC" -c advice.detachedHead=false checkout --quiet --force "$ARCHIFY_COMMIT"

if [[ -e $LINK && ! -L $LINK ]]; then
  echo "error: $LINK exists and is not a symlink" >&2
  exit 1
fi
ln -sfn "$SRC/archify" "$LINK"
echo "archify $ARCHIFY_TAG ($ARCHIFY_COMMIT) -> $LINK"
