#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
godot_bin="${GODOT_BIN:-$HOME/godot/bin/godot.linuxbsd.editor.x86_64}"
test_project="$(mktemp -d /tmp/godot-charts-m1.XXXXXX)"
trap 'rm -rf "$test_project"' EXIT

mkdir -p "$test_project/addons" "$test_project/tests/m1"
cp -R "$repo_root/addons/godot-charts" "$test_project/addons/godot-charts"
cp -R "$repo_root/tests/m1/fixtures" "$test_project/tests/m1/fixtures"
cp "$repo_root/tests/m1/godot/project.godot" "$test_project/project.godot"
cp "$repo_root/tests/m1/godot/test_m1_replay.gd" "$test_project/test_m1_replay.gd"

mkdir -p "$test_project/home" "$test_project/data" "$test_project/cache"
HOME="$test_project/home" \
XDG_DATA_HOME="$test_project/data" \
XDG_CACHE_HOME="$test_project/cache" \
"$godot_bin" --headless --path "$test_project" --script res://test_m1_replay.gd
