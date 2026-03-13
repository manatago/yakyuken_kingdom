#!/usr/bin/env bash
# Restore godot/assets from an archive in archives/.
# Usage:
#   ./scripts/restore-assets.sh              # latest archive
#   ./scripts/restore-assets.sh 016850c      # specific commit hash
#   ./scripts/restore-assets.sh assets_016850c_20260313.tar.gz  # specific file

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ASSETS_DIR="$REPO_ROOT/godot/assets"
ARCHIVES_DIR="$REPO_ROOT/archives"

if [ ! -d "$ARCHIVES_DIR" ]; then
    echo "Error: $ARCHIVES_DIR not found" >&2
    exit 1
fi

# Resolve which archive to use
ARCHIVE=""
if [ $# -eq 0 ]; then
    # Use the latest archive (by filename sort)
    ARCHIVE=$(ls -1 "$ARCHIVES_DIR"/assets_*.tar.gz 2>/dev/null | sort -r | head -1)
elif [ -f "$ARCHIVES_DIR/$1" ]; then
    # Exact filename given
    ARCHIVE="$ARCHIVES_DIR/$1"
elif ls "$ARCHIVES_DIR"/assets_"$1"_*.tar.gz 1>/dev/null 2>&1; then
    # Commit hash given — pick latest date for that hash
    ARCHIVE=$(ls -1 "$ARCHIVES_DIR"/assets_"$1"_*.tar.gz | sort -r | head -1)
fi

if [ -z "$ARCHIVE" ] || [ ! -f "$ARCHIVE" ]; then
    echo "Error: No matching archive found" >&2
    echo "Available archives:" >&2
    ls -1 "$ARCHIVES_DIR"/assets_*.tar.gz 2>/dev/null || echo "  (none)"
    exit 1
fi

echo "Archive: $(basename "$ARCHIVE")"

if [ -d "$ASSETS_DIR" ]; then
    echo "Removing existing assets..."
    rm -rf "$ASSETS_DIR"
fi

echo "Extracting..."
tar xzf "$ARCHIVE" -C "$REPO_ROOT/godot"

COUNT=$(find "$ASSETS_DIR" -type f | wc -l)
echo "Done: $COUNT files restored to godot/assets/"
