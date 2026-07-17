#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
godot_bin="${GODOT_BIN:-$HOME/godot/bin/godot.linuxbsd.editor.x86_64}"
test_project="$(mktemp -d /tmp/godot-charts-webxr.XXXXXX)"
trap 'rm -rf "$test_project"' EXIT

mkdir -p "$test_project/addons"
"$repo_root/scripts/build-m1-addon.sh" "$test_project/addons/godot-charts"
cp "$repo_root/tests/m3/godot/project.godot" "$test_project/project.godot"
cp "$repo_root/tests/m3/godot/test_webxr_session.gd" "$test_project/test_webxr_session.gd"
mkdir -p "$test_project/home" "$test_project/data" "$test_project/cache"
export HOME="$test_project/home" XDG_DATA_HOME="$test_project/data" XDG_CACHE_HOME="$test_project/cache"

"$godot_bin" --headless --editor --path "$test_project" --quit-after 2
"$godot_bin" --headless --path "$test_project" --script res://test_webxr_session.gd
