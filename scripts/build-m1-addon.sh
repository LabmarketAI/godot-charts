#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 /path/to/output/addons/godot-charts" >&2
    exit 1
fi

destination="$1"
if [[ -e "$destination" ]]; then
    echo "Refusing to overwrite existing path: $destination" >&2
    exit 1
fi

mkdir -p "$destination"
for directory in core diagnostics frames integrations interactions protocol renderers schemas session tables; do
    cp -R "$repo_root/addons/godot-charts/$directory" "$destination/$directory"
done
cp "$repo_root/addons/godot-charts/LICENSE" "$destination/LICENSE"
cp "$repo_root/addons/godot-charts/icon.svg" "$destination/icon.svg"
cp "$repo_root/addons/godot-charts/m1_plugin.gd" "$destination/plugin.gd"
cp "$repo_root/packaging/m1/plugin.cfg" "$destination/plugin.cfg"
cp "$repo_root/packaging/m1/README.md" "$destination/README.md"

"$repo_root/scripts/check-m1-addon.sh" "$destination"
echo "Built pure-GDScript M1 addon: $destination"
