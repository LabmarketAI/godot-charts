#!/usr/bin/env bash
set -euo pipefail

REPO="LabmarketAI/godot-desktop-capture"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEMO_DIR="$DIR/demo"
ADDONS_DIR="$DEMO_DIR/addons"
GDC_DIR="$ADDONS_DIR/godot-desktop-capture"

echo "Fetching latest release information for $REPO..."
API_URL="https://api.github.com/repos/$REPO/releases/latest"
DOWNLOAD_URL=$(curl -sL "$API_URL" | grep -o "https://github.com/.*\.zip" | head -n 1)

if [[ -z "$DOWNLOAD_URL" ]]; then
    echo "Error: No .zip asset found in the latest release!"
    exit 1
fi

ZIP_FILE="$DIR/godot-desktop-capture-latest.zip"

echo "Downloading $DOWNLOAD_URL..."
curl -sL "$DOWNLOAD_URL" -o "$ZIP_FILE"

echo "Cleaning up old version..."
if [[ -d "$GDC_DIR" ]]; then
    rm -rf "$GDC_DIR"
fi

echo "Extracting to demo/ folder..."
mkdir -p "$DEMO_DIR"
unzip -q -o "$ZIP_FILE" -d "$DEMO_DIR"
rm "$ZIP_FILE"

echo "Successfully updated godot-desktop-capture!"
