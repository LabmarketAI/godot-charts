#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
godot_bin="${GODOT_BIN:-$HOME/godot/bin/godot.linuxbsd.editor.x86_64}"
test_project="$(mktemp -d /tmp/godot-charts-m2.XXXXXX)"
trap 'rm -rf "$test_project"' EXIT

"$repo_root/scripts/check-m1-boundaries.sh"
python3 "$repo_root/tools/assets/validate_glb_asset_pack.py"
mkdir -p "$test_project/addons"
"$repo_root/scripts/build-m1-addon.sh" "$test_project/addons/godot-charts"
mkdir -p "$test_project/tests/m1"
cp -R "$repo_root/tests/m1/fixtures" "$test_project/tests/m1/fixtures"
cp "$repo_root/tests/m2/godot/project.godot" "$test_project/project.godot"
cp "$repo_root/tests/visual/godot/glb_import_probe.tscn" "$test_project/glb_import_probe.tscn"
cp "$repo_root/tests/m2/godot/test_m2_frame_state.gd" "$test_project/test_m2_frame_state.gd"
cp "$repo_root/tests/m2/godot/test_m2_input_adapters.gd" "$test_project/test_m2_input_adapters.gd"
mkdir -p "$test_project/home" "$test_project/data" "$test_project/cache"
export HOME="$test_project/home" XDG_DATA_HOME="$test_project/data" XDG_CACHE_HOME="$test_project/cache"
"$godot_bin" --headless --editor --path "$test_project" --import
if ! find "$test_project/.godot/imported" -name 'control_handle_linear.glb-*.scn' -print -quit | grep -q .; then
    echo "GLB import cache was not created for control_handle_linear.glb" >&2
    exit 1
fi
"$godot_bin" --headless --path "$test_project" --script res://test_m2_frame_state.gd
"$godot_bin" --headless --path "$test_project" --script res://test_m2_input_adapters.gd
