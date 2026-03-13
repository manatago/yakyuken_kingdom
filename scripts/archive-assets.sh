#!/usr/bin/env bash
# Archive godot/assets into archives/ with commit hash and date.
# Usage: ./scripts/archive-assets.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ASSETS_DIR="$REPO_ROOT/godot/assets"
ARCHIVES_DIR="$REPO_ROOT/archives"

if [ ! -d "$ASSETS_DIR" ]; then
    echo "Error: $ASSETS_DIR not found" >&2
    exit 1
fi

COMMIT_HASH=$(git -C "$REPO_ROOT" rev-parse --short HEAD)
DATE=$(date +%Y%m%d)
FILENAME="assets_${COMMIT_HASH}_${DATE}.tar.gz"
FILEPATH="$ARCHIVES_DIR/$FILENAME"

mkdir -p "$ARCHIVES_DIR"

if [ -f "$FILEPATH" ]; then
    echo "Archive already exists: $FILEPATH"
    exit 0
fi

echo "Creating archive: $FILENAME"
tar czf "$FILEPATH" -C "$REPO_ROOT/godot" assets

SIZE=$(du -h "$FILEPATH" | cut -f1)
echo "Done: $FILEPATH ($SIZE)"
