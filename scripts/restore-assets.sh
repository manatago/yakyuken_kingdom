#!/usr/bin/env bash
# Restore godot/assets from a zip archive in the project root.
# Usage:
#   ./scripts/restore-assets.sh              # latest zip
#   ./scripts/restore-assets.sh c8effaa      # specific commit hash
#   ./scripts/restore-assets.sh assets_c8effaa_20260403.zip  # specific file

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ASSETS_DIR="$REPO_ROOT/godot/assets"

# Resolve which archive to use
ARCHIVE=""
if [ $# -eq 0 ]; then
    # Use the latest zip (by filename sort)
    ARCHIVE=$(ls -1 "$REPO_ROOT"/assets_*.zip 2>/dev/null | sort -r | head -1)
elif [ -f "$REPO_ROOT/$1" ]; then
    # Exact filename given
    ARCHIVE="$REPO_ROOT/$1"
elif [ -f "$1" ]; then
    # Full path given
    ARCHIVE="$1"
elif ls "$REPO_ROOT"/assets_"$1"_*.zip 1>/dev/null 2>&1; then
    # Commit hash given
    ARCHIVE=$(ls -1 "$REPO_ROOT"/assets_"$1"_*.zip | sort -r | head -1)
fi

if [ -z "$ARCHIVE" ] || [ ! -f "$ARCHIVE" ]; then
    echo "Error: No matching archive found" >&2
    echo "Available archives:" >&2
    ls -1 "$REPO_ROOT"/assets_*.zip 2>/dev/null || echo "  (none)"
    exit 1
fi

echo "Archive: $(basename "$ARCHIVE")"

if [ -d "$ASSETS_DIR" ]; then
    echo "Removing existing assets..."
    rm -rf "$ASSETS_DIR"
fi

echo "Extracting to godot/ ..."
cd "$REPO_ROOT/godot"

# Try unzip first, fall back to python
if command -v unzip &>/dev/null; then
    unzip -qo "$ARCHIVE"
elif command -v python3 &>/dev/null; then
    python3 -c "
import zipfile, sys
with zipfile.ZipFile('$ARCHIVE', 'r') as zf:
    zf.extractall('.')
"
elif command -v python &>/dev/null; then
    python -c "
import zipfile, sys
with zipfile.ZipFile('$ARCHIVE', 'r') as zf:
    zf.extractall('.')
"
else
    echo "Error: No unzip, python3, or python found" >&2
    exit 1
fi

COUNT=$(find "$ASSETS_DIR" -type f | wc -l)
echo "Done: $COUNT files restored to godot/assets/"
