#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
src_dir="$repo_root/addons/godot-charts"
dst_dir="$repo_root/demo/addons/godot-charts"

if [[ ! -d "$src_dir" || ! -d "$dst_dir" ]]; then
  echo "Expected directories missing:" >&2
  echo "  source: $src_dir" >&2
  echo "  target: $dst_dir" >&2
  exit 1
fi

if diff -qr "$src_dir" "$dst_dir" >/tmp/addon_sync_diff.txt; then
  echo "Addon directories are in sync."
  exit 0
fi

echo "Addon directories are out of sync:" >&2
head -n 60 /tmp/addon_sync_diff.txt >&2

echo >&2

echo "Run this command and commit the result:" >&2

echo "  bash scripts/sync-demo-addon.sh" >&2

exit 1
