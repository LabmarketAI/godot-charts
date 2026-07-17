#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
godot_bin="${GODOT_BIN:-$HOME/godot/bin/godot.linuxbsd.editor.x86_64}"
python_bin="${PYTHON_BIN:-$repo_root/.venv/bin/python}"
test_project="$(mktemp -d /tmp/godot-charts-companion.XXXXXX)"
server_pid=""
cleanup() {
    [[ -z "$server_pid" ]] || kill "$server_pid" 2>/dev/null || true
    rm -rf "$test_project"
}
trap cleanup EXIT

mkdir -p "$test_project/addons"
"$repo_root/scripts/build-m1-addon.sh" "$test_project/addons/godot-charts"
cp "$repo_root/tests/live/godot/project.godot" "$test_project/project.godot"
cp "$repo_root/tests/live/godot/test_companion_transport.gd" "$test_project/test_companion_transport.gd"
ready_file="$test_project/server-ready.json"
PYTHONPATH="$repo_root/python" "$python_bin" "$repo_root/tools/live/companion_scatter_server.py" --ready-file "$ready_file" &
server_pid=$!
for _ in {1..100}; do
    [[ -s "$ready_file" ]] && break
    kill -0 "$server_pid" 2>/dev/null || { wait "$server_pid"; exit 1; }
    sleep 0.05
done
[[ -s "$ready_file" ]] || { echo "Companion server did not become ready" >&2; exit 1; }
export GODOT_CHARTS_LIVE_PORT
GODOT_CHARTS_LIVE_PORT="$($python_bin -c 'import json,sys; print(json.load(open(sys.argv[1]))["port"])' "$ready_file")"
mkdir -p "$test_project/home" "$test_project/data" "$test_project/cache"
export HOME="$test_project/home" XDG_DATA_HOME="$test_project/data" XDG_CACHE_HOME="$test_project/cache"
"$godot_bin" --headless --editor --path "$test_project" --quit-after 2
"$godot_bin" --headless --path "$test_project" --script res://test_companion_transport.gd
wait "$server_pid"
