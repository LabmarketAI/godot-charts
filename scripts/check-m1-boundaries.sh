#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
addon="${GODOT_CHARTS_ADDON_ROOT:-$repo_root/addons/godot-charts}"

search_lines() {
    if [[ "${M1_SEARCH_TOOL:-}" == "grep" ]]; then
        grep -REn "$@"
    elif command -v rg >/dev/null 2>&1; then
        rg -n "$@"
    else
        grep -REn "$@"
    fi
}

if search_lines '^extends (Node|Node3D|Control|Resource|EditorPlugin)|res://addons/godot-charts/(protocol|renderers|tables|interactions|session|diagnostics|charts|circuits|utils|widgets)/' "$addon/core"; then
    echo "Core boundary violation: core must remain RefCounted and may import only core." >&2
    exit 1
fi

if search_lines '^extends (Node|Node3D|Control|Resource|EditorPlugin)|res://addons/godot-charts/(protocol|renderers|tables|interactions|session|diagnostics|integrations|charts|circuits|utils|widgets)/' "$addon/frames"; then
    echo "Frame-state boundary violation: frames must remain RefCounted and may import only frame/core state." >&2
    exit 1
fi

if search_lines '^extends (Node|Node3D|Control|Resource|EditorPlugin)|res://addons/godot-charts/(protocol|renderers|tables|session|diagnostics|integrations|charts|circuits|utils|widgets)/' "$addon/interactions"; then
    echo "Interaction boundary violation: interactions must remain RefCounted and device/presentation independent." >&2
    exit 1
fi

if search_lines 'res://addons/godot-charts/(renderers|tables|interactions|session|diagnostics|charts|circuits|utils|widgets)/' "$addon/protocol"; then
    echo "Protocol boundary violation: protocol may depend on core/protocol only." >&2
    exit 1
fi

if search_lines 'res://addons/godot-charts/(protocol|session|diagnostics|charts|circuits|utils|widgets)/' "$addon/renderers" "$addon/tables"; then
    echo "Presentation boundary violation: renderer/table adapters must not own protocol or session policy." >&2
    exit 1
fi

if search_lines 'res://addons/godot-charts/(charts|circuits|utils|widgets)/' \
    "$addon/core" "$addon/protocol" "$addon/renderers" "$addon/tables" \
    "$addon/frames" "$addon/interactions" "$addon/session" "$addon/diagnostics"; then
    echo "M1 boundary violation: preview code imports a legacy surface." >&2
    exit 1
fi

echo "M1 dependency-boundary audit passed."
