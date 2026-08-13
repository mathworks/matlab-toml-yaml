#!/usr/bin/env bash
#
# sync-to-github.sh — assemble the public release tree from release/manifest.txt.
#
# This repository contains development-only content that must NOT ship to the
# public repository at github.com/mathworks/matlab-toml-yaml. This script copies
# only the paths listed in release/manifest.txt into a clean output tree.
#
# It does NOT push. Pushing to the public remote is a separate, manual, reviewed
# step (deferred until we decide whether development moves to GitHub).
#
# Usage:
#   release/sync-to-github.sh                 # dry run: print what would ship
#   release/sync-to-github.sh --out DIR       # assemble the release tree in DIR
#
set -euo pipefail

# Resolve repo root as the parent of this script's directory.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MANIFEST="$SCRIPT_DIR/manifest.txt"

OUT=""
DRY_RUN=1
while [[ $# -gt 0 ]]; do
    case "$1" in
        --out)
            OUT="${2:-}"
            DRY_RUN=0
            shift 2
            ;;
        -h|--help)
            grep '^#' "$0" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        *)
            echo "Unknown argument: $1" >&2
            exit 2
            ;;
    esac
done

if [[ ! -f "$MANIFEST" ]]; then
    echo "Manifest not found: $MANIFEST" >&2
    exit 1
fi

# Read manifest into an array, stripping comments and blank lines.
paths=()
while IFS= read -r line; do
    line="${line%%#*}"                       # strip trailing comments
    line="$(echo "$line" | xargs 2>/dev/null || true)"  # trim whitespace
    [[ -z "$line" ]] && continue
    paths+=("$line")
done < "$MANIFEST"

# Validate that every listed path exists.
missing=0
for p in "${paths[@]}"; do
    if [[ ! -e "$REPO_ROOT/$p" ]]; then
        echo "MISSING: $p (listed in manifest but not found in repo)" >&2
        missing=1
    fi
done
if [[ "$missing" -ne 0 ]]; then
    echo "Aborting: manifest references paths that do not exist." >&2
    exit 1
fi

if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "Release contents (dry run) — the following would ship:"
    for p in "${paths[@]}"; do
        if [[ -d "$REPO_ROOT/$p" ]]; then
            echo "  $p/  (directory)"
        else
            echo "  $p"
        fi
    done
    echo
    echo "Run with '--out DIR' to assemble the release tree."
    exit 0
fi

# Assemble the release tree.
if [[ -z "$OUT" ]]; then
    echo "--out requires a directory argument" >&2
    exit 2
fi

mkdir -p "$OUT"
# Refuse to clobber a non-empty directory that we did not create this run.
if [[ -n "$(ls -A "$OUT" 2>/dev/null)" ]]; then
    echo "Output directory is not empty: $OUT" >&2
    echo "Remove it or choose an empty directory." >&2
    exit 1
fi

for p in "${paths[@]}"; do
    src="$REPO_ROOT/$p"
    dest="$OUT/$p"
    mkdir -p "$(dirname "$dest")"
    if [[ -d "$src" ]]; then
        # Copy directory contents, excluding OS cruft.
        rsync -a --exclude='.DS_Store' "$src/" "$dest/"
    else
        cp "$src" "$dest"
    fi
    echo "copied: $p"
done

echo
echo "Release tree assembled in: $OUT"
echo "Review it, then push to the public remote manually (deferred)."
