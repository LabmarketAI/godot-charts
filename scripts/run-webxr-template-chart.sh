#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
project_src="${WEBXR_TEMPLATE_CHART_SRC:-$repo_root/examples/webxr-template-chart}"
timestamp="$(date +%Y%m%d-%H%M%S)"
output="${WEBXR_TEMPLATE_CHART_OUTPUT:-/tmp/godot-webxr-template-chart-$timestamp}"
project="$output/project"
web="$output/web"
godot_home="$output/godot-home"
port="${WEBXR_PORT:-8457}"
lan_ip="${WEBXR_LAN_IP:-}"
log_path="${WEBXR_LOG:-$repo_root/.local/webxr-host/logs/template-chart-$timestamp.log}"
godot_bin="${GODOT_BIN:-/usr/bin/godot}"
export_data_home="${GODOT_EXPORT_DATA_HOME:-$HOME/.local/share}"
cert_dir="$repo_root/.local/webxr-host/certs"
cert="$cert_dir/localhost.crt"
key="$cert_dir/localhost.key"

usage() {
    cat >&2 <<EOF
Usage: $0 [--output /tmp/path] [--ip LAN_IP] [--port PORT] [--log /path/to/log]

Build and host examples/webxr-template-chart for Quest/WebXR testing.

Environment:
  GODOT_BIN                Godot executable. Default: /usr/bin/godot
  GODOT_EXPORT_DATA_HOME   Export template data home. Default: ~/.local/share
  WEBXR_LAN_IP             IP printed for headset URL.
  WEBXR_PORT               HTTPS port. Default: 8457
  WEBXR_LOG                Browser/Godot log path.
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --output)
            output="$2"
            project="$output/project"
            web="$output/web"
            godot_home="$output/godot-home"
            shift 2
            ;;
        --ip)
            lan_ip="$2"
            shift 2
            ;;
        --port)
            port="$2"
            shift 2
            ;;
        --log)
            log_path="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown argument: $1" >&2
            usage
            exit 1
            ;;
    esac
done

detect_wifi_ip() {
    if command -v ip >/dev/null 2>&1; then
        ip -o -4 addr show scope global 2>/dev/null \
            | awk '$2 ~ /^wl/ { split($4, parts, "/"); print parts[1]; exit }' || true
    fi
}

detect_route_ip() {
    if command -v ip >/dev/null 2>&1; then
        ip route get 1.1.1.1 2>/dev/null \
            | awk '{ for (i = 1; i <= NF; i++) if ($i == "src") { print $(i + 1); exit } }' || true
    fi
    if command -v hostname >/dev/null 2>&1; then
        hostname -I 2>/dev/null | awk '{ print $1; exit }' || true
    fi
}

print_all_endpoints() {
    if command -v ip >/dev/null 2>&1; then
        ip -o -4 addr show scope global 2>/dev/null \
            | awk -v port="$port" '{ split($4, parts, "/"); print "  https://" parts[1] ":" port "/  (" $2 ")" }' || true
    fi
}

ensure_port_available() {
    if ss -ltn 2>/dev/null | awk '{print $4}' | grep -Eq "(:|\\])$port$"; then
        echo "Port $port is already in use. Stop that process or run with --port PORT." >&2
        ss -ltnp 2>/dev/null | grep -E "(:|\\])$port\\b" >&2 || true
        exit 1
    fi
}

ensure_cert() {
    if [[ -s "$cert" && -s "$key" ]]; then
        return
    fi
    mkdir -p "$cert_dir"
    openssl req -x509 -newkey rsa:2048 -nodes -days 14 \
        -keyout "$key" \
        -out "$cert" \
        -subj "/CN=localhost" \
        -addext "subjectAltName=DNS:localhost,IP:127.0.0.1"
}

run_godot() {
    HOME="$godot_home" XDG_CONFIG_HOME="$godot_home/.config" XDG_CACHE_HOME="$godot_home/.cache" XDG_DATA_HOME="$export_data_home" \
        "$godot_bin" "$@"
}

if [[ ! -d "$project_src" || ! -f "$project_src/project.godot" ]]; then
    echo "WebXR template chart project not found: $project_src" >&2
    exit 1
fi
if [[ -e "$output" ]]; then
    echo "Refusing to overwrite existing path: $output" >&2
    exit 1
fi
if [[ ! -x "$godot_bin" ]]; then
    echo "Godot binary is not executable: $godot_bin" >&2
    exit 1
fi

mkdir -p "$output" "$web" "$godot_home/.config" "$godot_home/.cache"
cp -R "$project_src" "$project"
python3 - "$project/project.godot" <<'PY'
from pathlib import Path
import sys

project_file = Path(sys.argv[1])
text = project_file.read_text()
desktop_main = 'run/main_scene="res://game/chart_inspection/chart_inspection_desktop.tscn"'
webxr_main = 'run/main_scene="res://game/main.tscn"'
if desktop_main not in text and webxr_main not in text:
    raise SystemExit("Could not find run/main_scene in copied WebXR project")
text = text.replace(desktop_main, webxr_main)
desktop_xr = "openxr/enabled=false"
webxr_xr = "openxr/enabled=true"
if desktop_xr in text:
    text = text.replace(desktop_xr, webxr_xr)
elif webxr_xr not in text:
    xr_header = "[xr]\n\n"
    if xr_header not in text:
        raise SystemExit("Could not find [xr] section in copied WebXR project")
    text = text.replace(xr_header, xr_header + webxr_xr + "\n", 1)
project_file.write_text(text)
PY
fresh_addon="$output/fresh-godot-charts-addon"
"$repo_root/scripts/build-m1-addon.sh" "$fresh_addon"
rm -rf "$project/addons/godot-charts"
mv "$fresh_addon" "$project/addons/godot-charts"

python3 "$repo_root/tools/assets/validate_glb_asset_pack.py" \
    --manifest "$project/addons/godot-charts/assets/visual/glb/asset_pack_manifest.json"

export GODOT_EXPORT_DATA_HOME="$export_data_home"
run_godot --headless --import --path "$project" || \
    echo "Godot editor import returned nonzero; continuing to verify export artifacts." >&2
if ! find "$project/.godot/imported" -name 'control_handle_linear.glb-*.scn' -print -quit | grep -q .; then
    echo "GLB import cache was not created for control_handle_linear.glb" >&2
    exit 1
fi
run_godot --headless --path "$project" --export-release WebXR "$web/index.html" || \
    echo "Godot WebXR export returned nonzero; continuing to verify export artifacts." >&2

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

if [[ -z "$lan_ip" ]]; then
    lan_ip="$(detect_wifi_ip)"
fi
if [[ -z "$lan_ip" ]]; then
    lan_ip="$(detect_route_ip)"
fi
if [[ -z "$lan_ip" ]]; then
    echo "Could not detect LAN IP. Pass --ip 192.168.x.y." >&2
    exit 1
fi

ensure_port_available
ensure_cert

cat <<EOF

============================================================
WEBXR TEMPLATE CHART HEADSET URL
  https://$lan_ip:$port/
============================================================

Export entry:
  res://game/main.tscn

Loaded VR chart scene:
  res://game/chart_inspection/chart_inspection_vr.tscn

Desktop editor entry:
  res://game/chart_inspection/chart_inspection_desktop.tscn

Source:
  $project_src

Built Web export:
  $web

All detected LAN endpoints:
$(print_all_endpoints)

Quest/browser log:
  $log_path

Keep this terminal open. Press Ctrl+C to stop the server.
============================================================

EOF

exec node "$repo_root/scripts/webxr-host-server.mjs" \
    --root "$web" \
    --host 0.0.0.0 \
    --port "$port" \
    --cert "$cert" \
    --key "$key" \
    --log "$log_path"
