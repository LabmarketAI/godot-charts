#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
godot_bin="${GODOT_BIN:-$HOME/godot/bin/godot.linuxbsd.editor.x86_64}"
python_bin="${PYTHON_BIN:-$repo_root/.venv/bin/python}"
browser_bin="${BROWSER_BIN:-brave-browser}"
test_root="$(mktemp -d /tmp/godot-charts-browser.XXXXXX)"
server_pid=""
browser_pid=""
cleanup() {
    [[ -z "$browser_pid" ]] || kill "$browser_pid" 2>/dev/null || true
    [[ -z "$server_pid" ]] || kill "$server_pid" 2>/dev/null || true
    rm -rf "$test_root"
}
trap cleanup EXIT
trap 'echo "--- browser log ---" >&2; tail -80 "$test_root/browser.log" >&2 2>/dev/null || true; echo "--- server log ---" >&2; tail -40 "$test_root/server.log" >&2 2>/dev/null || true' ERR

web_port="$($python_bin -c 'import socket; s=socket.socket(); s.bind(("127.0.0.1", 0)); print(s.getsockname()[1]); s.close()')"
debug_port="$($python_bin -c 'import socket; s=socket.socket(); s.bind(("127.0.0.1", 0)); print(s.getsockname()[1]); s.close()')"
GODOT_EXPORT_DATA_HOME="${GODOT_EXPORT_DATA_HOME:-$HOME/.local/share}" \
    GODOT_BIN="$godot_bin" "$repo_root/scripts/build-web-example.sh" "$test_root/build"

"$python_bin" -m http.server "$web_port" --bind 127.0.0.1 --directory "$test_root/build/web" >"$test_root/server.log" 2>&1 &
server_pid=$!
"$browser_bin" --headless=new --no-sandbox --disable-gpu --enable-unsafe-swiftshader \
    --remote-debugging-port="$debug_port" --user-data-dir="$test_root/browser" --window-size=1280,720 \
    "http://127.0.0.1:$web_port/index.html?live_wss=wss%3A%2F%2F127.0.0.1%3A1" >"$test_root/browser.log" 2>&1 &
browser_pid=$!

node "$repo_root/tests/m3/browser/browser_smoke.mjs" "$debug_port" "${M3_REPORT_PATH:-}"
if rg -n "SCRIPT ERROR|WebAssembly.*error|Unhandled|FATAL" "$test_root/browser.log"; then
    echo "Browser log contains a fatal Godot or WebAssembly error." >&2
    exit 1
fi
