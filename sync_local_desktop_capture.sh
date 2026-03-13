#!/usr/bin/env bash
set -euo pipefail

CHARTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CAPTURE_DIR="$(dirname "$CHARTS_DIR")/godot-desktop-capture"

if [[ ! -d "$CAPTURE_DIR" ]]; then
    echo "Error: Local godot-desktop-capture repo not found at $CAPTURE_DIR"
    exit 1
fi

SOURCE_ADDON="$CAPTURE_DIR/project/addons/godot-desktop-capture"
DEST_ADDON="$CHARTS_DIR/demo/addons/godot-desktop-capture"

if [[ ! -d "$SOURCE_ADDON" ]]; then
    echo "Error: Compiled addon not found in $SOURCE_ADDON. Did you run the build script?"
    exit 1
fi

echo "Syncing godot-desktop-capture from local sibling repository..."

# Sync files (Remove old destination and copy new)
if [[ -d "$DEST_ADDON" ]]; then
    rm -rf "$DEST_ADDON"
fi

mkdir -p "$(dirname "$DEST_ADDON")"
cp -r "$SOURCE_ADDON" "$DEST_ADDON"

echo "Successfully synced local godot-desktop-capture to the demo project!"