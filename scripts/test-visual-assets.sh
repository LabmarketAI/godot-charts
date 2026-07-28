#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
godot_bin="${GODOT_BIN:-godot}"
test_project="$(mktemp -d "${TMPDIR:-/tmp}/godot-charts-visual-assets.XXXXXX")"
xdg_root="$test_project/xdg"

mkdir -p "$test_project/addons" "$test_project/tests/visual"
mkdir -p "$xdg_root/config" "$xdg_root/data" "$xdg_root/cache"
python3 "$repo_root/tools/assets/validate_glb_asset_pack.py"
"$repo_root/scripts/build-m1-addon.sh" "$test_project/addons/godot-charts"
if [ ! -f "$test_project/addons/godot-charts/assets/visual/glb/asset_pack_manifest.json" ]; then
    echo "GLB asset manifest was not packaged into the addon build" >&2
    exit 1
fi
if [ ! -f "$test_project/addons/godot-charts/assets/visual/glb/control_handle_linear.glb" ]; then
    echo "GLB asset was not packaged into the addon build" >&2
    exit 1
fi
if find "$test_project/addons/godot-charts" \( -name '*.blend' -o -name '*.blend1' \) -print -quit | grep -q .; then
    echo "Blender authoring files must not be packaged into the runtime addon" >&2
    exit 1
fi
cp "$repo_root/tests/m1/godot/project.godot" "$test_project/project.godot"
cp "$repo_root/tests/visual/godot/test_visual_assets.gd" "$test_project/test_visual_assets.gd"
cp "$repo_root/tests/visual/godot/glb_import_probe.tscn" "$test_project/glb_import_probe.tscn"
cp "$repo_root/examples/visual-assets/main.gd" "$test_project/main.gd"
cp "$repo_root/examples/visual-assets/main.tscn" "$test_project/main.tscn"

XDG_CONFIG_HOME="$xdg_root/config" XDG_DATA_HOME="$xdg_root/data" XDG_CACHE_HOME="$xdg_root/cache" \
    "$godot_bin" --headless --editor --path "$test_project" --import
if ! find "$test_project/.godot/imported" -name 'control_handle_linear.glb-*.scn' -print -quit | grep -q .; then
    echo "GLB import cache was not created for control_handle_linear.glb" >&2
    exit 1
fi
XDG_CONFIG_HOME="$xdg_root/config" XDG_DATA_HOME="$xdg_root/data" XDG_CACHE_HOME="$xdg_root/cache" \
    "$godot_bin" --headless --path "$test_project" --script res://test_visual_assets.gd
