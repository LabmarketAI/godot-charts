#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
godot_bin="${GODOT_BIN:-$HOME/godot/bin/godot.linuxbsd.editor.x86_64}"
test_root="$(mktemp -d /tmp/godot-charts-web-ui.XXXXXX)"
trap 'rm -rf "$test_root"' EXIT

"$repo_root/scripts/prepare-m1-example.sh" "$test_root/project"
cp "$repo_root/tests/m3/godot/test_web_ui.gd" "$test_root/project/test_web_ui.gd"
mkdir -p "$test_root/home" "$test_root/data" "$test_root/cache"
export HOME="$test_root/home" XDG_DATA_HOME="$test_root/data" XDG_CACHE_HOME="$test_root/cache"

"$godot_bin" --headless --editor --path "$test_root/project" --quit-after 2
"$godot_bin" --headless --path "$test_root/project" --script res://test_web_ui.gd
