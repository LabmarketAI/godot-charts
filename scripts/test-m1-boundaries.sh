#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fixture_root="$(mktemp -d "${TMPDIR:-/tmp}/godot-charts-boundaries.XXXXXX")"
trap 'rm -rf "$fixture_root"' EXIT

cp -R "$repo_root/addons/godot-charts" "$fixture_root/addon"

M1_SEARCH_TOOL=grep GODOT_CHARTS_ADDON_ROOT="$fixture_root/addon" \
    "$repo_root/scripts/check-m1-boundaries.sh"

printf '%s\n' \
    'const Forbidden = preload("res://addons/godot-charts/widgets/forbidden.gd")' \
    >> "$fixture_root/addon/core/forbidden_fixture.gd"

if M1_SEARCH_TOOL=grep GODOT_CHARTS_ADDON_ROOT="$fixture_root/addon" \
        "$repo_root/scripts/check-m1-boundaries.sh"; then
    echo "Boundary audit accepted a forbidden dependency." >&2
    exit 1
fi

echo "M1 boundary fallback regression test passed."
