#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 /path/to/addons/godot-charts" >&2
    exit 1
fi

addon="$1"
test -f "$addon/plugin.cfg"
test -f "$addon/plugin.gd"
test -d "$addon/core"
test -d "$addon/protocol"
test -d "$addon/renderers"

forbidden="$(find "$addon" -type f \( -name '*.cs' -o -name '*.csproj' -o -name '*.sln' -o -name '*.dll' -o -name '*.so' -o -name '*.dylib' -o -name '*.pdb' \) -print)"
if [[ -n "$forbidden" ]]; then
    echo "M1 addon contains forbidden runtime/build files:" >&2
    echo "$forbidden" >&2
    exit 1
fi

if rg -n 'res://demo/|NuGet|Godot\.NET|System\.' "$addon"; then
    echo "M1 addon contains a forbidden demo or .NET dependency reference." >&2
    exit 1
fi

echo "M1 addon audit passed: pure GDScript/resources, no mandatory native or demo dependency."
