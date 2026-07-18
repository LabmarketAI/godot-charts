#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
godot_bin="${GODOT_BIN:-godot}"
test_project="$(mktemp -d "${TMPDIR:-/tmp}/godot-charts-visual-assets.XXXXXX")"
xdg_root="$test_project/xdg"

mkdir -p "$test_project/addons" "$test_project/tests/visual"
mkdir -p "$xdg_root/config" "$xdg_root/data" "$xdg_root/cache"
"$repo_root/scripts/build-m1-addon.sh" "$test_project/addons/godot-charts"
cp "$repo_root/tests/m1/godot/project.godot" "$test_project/project.godot"
cp "$repo_root/tests/visual/godot/test_visual_assets.gd" "$test_project/test_visual_assets.gd"

XDG_CONFIG_HOME="$xdg_root/config" XDG_DATA_HOME="$xdg_root/data" XDG_CACHE_HOME="$xdg_root/cache" \
    "$godot_bin" --headless --editor --path "$test_project" --quit-after 2
XDG_CONFIG_HOME="$xdg_root/config" XDG_DATA_HOME="$xdg_root/data" XDG_CACHE_HOME="$xdg_root/cache" \
    "$godot_bin" --headless --path "$test_project" --script res://test_visual_assets.gd
