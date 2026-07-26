#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
godot_bin="${GODOT_BIN:-godot}"
test_project="$(mktemp -d /tmp/godot-charts-2d.XXXXXX)"
trap 'rm -rf "$test_project"' EXIT

mkdir -p "$test_project/addons"
"$repo_root/scripts/build-m1-addon.sh" \
    "$test_project/addons/godot-charts"
cp "$repo_root/tests/charts_2d/godot/project.godot" \
    "$test_project/project.godot"
cp "$repo_root/tests/charts_2d/godot/test_charts_2d.gd" \
    "$test_project/test_charts_2d.gd"

mkdir -p "$test_project/user-data" "$test_project/data" "$test_project/cache"
XDG_DATA_HOME="$test_project/data" \
XDG_CACHE_HOME="$test_project/cache" \
"$godot_bin" --headless --editor --path "$test_project" \
    --log-file "$test_project/import.log" --quit
XDG_DATA_HOME="$test_project/data" \
XDG_CACHE_HOME="$test_project/cache" \
"$godot_bin" --headless --path "$test_project" \
    --log-file "$test_project/test.log" \
    --script res://test_charts_2d.gd
