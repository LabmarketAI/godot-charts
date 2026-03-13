#!/usr/bin/env bash
set -euo pipefail

REPO="GodotVR/godot-xr-tools"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEMO_DIR="$DIR/demo"
ADDONS_DIR="$DEMO_DIR/addons"
XRTOOLS_DIR="$ADDONS_DIR/godot-xr-tools"

echo "Fetching latest release information for $REPO..."
API_URL="https://api.github.com/repos/$REPO/releases/latest"
DOWNLOAD_URL=$(curl -sL "$API_URL" | grep -o "https://github.com/.*/godot-xr-tools\.zip" | head -n 1)

if [[ -z "$DOWNLOAD_URL" ]]; then
    echo "Error: godot-xr-tools.zip asset found in the latest release!"
    exit 1
fi

ZIP_FILE="$DIR/godot-xr-tools-latest.zip"

echo "Downloading $DOWNLOAD_URL..."
curl -sL "$DOWNLOAD_URL" -o "$ZIP_FILE"

echo "Cleaning up old version..."
if [[ -d "$XRTOOLS_DIR" ]]; then
    rm -rf "$XRTOOLS_DIR"
fi

echo "Extracting..."
unzip -q -o "$ZIP_FILE" -d "$DIR"
rm "$ZIP_FILE"

echo "Moving into place..."
mkdir -p "$ADDONS_DIR"
mv "$DIR/godot-xr-tools/addons/godot-xr-tools" "$ADDONS_DIR/"
rm -rf "$DIR/godot-xr-tools"

echo "Successfully updated godot-xr-tools!"
