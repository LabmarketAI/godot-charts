#!/usr/bin/env bash
# install.sh — copy the godot-charts addon into a target Godot 4 project.
#
# Usage:
#   ./install.sh /path/to/your-godot-project
#
# After running this script, open your project in Godot 4 and enable the
# plugin under Project → Project Settings → Plugins → Godot Charts.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ADDON_SRC="$REPO_DIR/addons/godot-charts"

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 /path/to/your-godot-project"
    exit 1
fi

TARGET_PROJECT="$1"
DEST="$TARGET_PROJECT/addons/godot-charts"

if [[ ! -d "$TARGET_PROJECT" ]]; then
    echo "Error: target project directory not found: $TARGET_PROJECT"
    exit 1
fi

echo "Installing godot-charts into: $DEST"
mkdir -p "$DEST"
cp -r "$ADDON_SRC/." "$DEST/"
echo "Done. Enable the plugin in Project → Project Settings → Plugins."
