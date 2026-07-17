#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 /path/to/output-project" >&2
    exit 1
fi

destination="$1"
if [[ -e "$destination" ]]; then
    echo "Refusing to overwrite existing path: $destination" >&2
    exit 1
fi

mkdir -p "$destination/addons" "$destination/fixtures"
"$repo_root/scripts/build-m1-addon.sh" "$destination/addons/godot-charts"
cp "$repo_root/examples/m1/project.godot" "$destination/project.godot"
cp "$repo_root/examples/m1/main.tscn" "$destination/main.tscn"
cp "$repo_root/examples/m1/main.gd" "$destination/main.gd"
cp "$repo_root/tests/m1/fixtures/"*.json "$destination/fixtures/"
echo "Prepared M1 example: $destination/project.godot"
