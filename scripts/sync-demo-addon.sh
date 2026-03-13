#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
src_dir="$repo_root/addons/godot-charts/"
dst_dir="$repo_root/demo/addons/godot-charts/"

if [[ ! -d "$src_dir" ]]; then
  echo "Source addon directory not found: $src_dir" >&2
  exit 1
fi

mkdir -p "$dst_dir"

rsync -a --delete \
  --exclude='.git/' \
  --exclude='.DS_Store' \
  "$src_dir" "$dst_dir"

echo "Synchronized: addons/godot-charts -> demo/addons/godot-charts"
