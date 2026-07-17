#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
godot_bin="${GODOT_BIN:-$HOME/godot/bin/godot.linuxbsd.editor.x86_64}"
project="$(mktemp -d /tmp/godot-charts-m1-example.XXXXXX)"
trap 'rm -rf "$project"' EXIT

"$repo_root/scripts/prepare-m1-example.sh" "$project/project"
mkdir -p "$project/home" "$project/data" "$project/cache"
export HOME="$project/home"
export XDG_DATA_HOME="$project/data"
export XDG_CACHE_HOME="$project/cache"

"$godot_bin" --headless --editor --path "$project/project" --quit-after 2
"$godot_bin" --headless --path "$project/project" --quit-after 3
