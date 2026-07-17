#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
godot_bin="${GODOT_BIN:-$HOME/godot/bin/godot.linuxbsd.editor.x86_64}"

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 /path/to/output-directory" >&2
    exit 1
fi

output="$(realpath -m "$1")"
project="$output/project"
web="$output/web"
if [[ -e "$output" ]]; then
    echo "Refusing to overwrite existing path: $output" >&2
    exit 1
fi

"$repo_root/scripts/prepare-m1-example.sh" "$project"
mkdir -p "$web" "$output/home" "$output/data" "$output/cache"
export HOME="$output/home"
export XDG_DATA_HOME="${GODOT_EXPORT_DATA_HOME:-$output/data}"
export XDG_CACHE_HOME="$output/cache"

"$godot_bin" --headless --editor --path "$project" --quit-after 2
"$godot_bin" --headless --path "$project" --export-release Web "$web/index.html"

for artifact in index.html index.js index.wasm index.pck; do
    if [[ ! -s "$web/$artifact" ]]; then
        echo "Missing or empty web export artifact: $web/$artifact" >&2
        exit 1
    fi
done
if ! grep -Fq 'const GODOT_THREADS_ENABLED = false;' "$web/index.html"; then
    echo "Web export is not using the required single-threaded baseline." >&2
    exit 1
fi
if ! grep -Fq '"gdextensionLibs":[]' "$web/index.html"; then
    echo "Web export unexpectedly enables or includes GDExtensions." >&2
    exit 1
fi
if find "$web" -type f \( -name '*.dll' -o -name '*.so' -o -name '*.dylib' \) -print -quit | grep -q .; then
    echo "Web export unexpectedly contains a native library." >&2
    exit 1
fi

echo "Built verified single-threaded web release: $web/index.html"
