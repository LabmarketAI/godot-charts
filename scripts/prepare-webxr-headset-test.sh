#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
output="${1:-/tmp/godot-charts-webxr-candidate}"
report_path="${M3_REPORT_PATH:-/tmp/godot-charts-flat-web-report.json}"
export_data_home="${GODOT_EXPORT_DATA_HOME:-$HOME/.local/share}"

resolve_godot_bin() {
    if [[ -n "${GODOT_BIN:-}" ]]; then
        printf '%s\n' "$GODOT_BIN"
        return
    fi

    if command -v godot >/dev/null 2>&1; then
        command -v godot
        return
    fi

    local candidate
    for candidate in \
        "$HOME/src/godot/bin/godot.linuxbsd.editor.x86_64" \
        "$HOME/godot/bin/godot.linuxbsd.editor.x86_64"
    do
        if [[ -x "$candidate" ]]; then
            printf '%s\n' "$candidate"
            return
        fi
    done

    printf '%s\n' "$HOME/godot/bin/godot.linuxbsd.editor.x86_64"
}

godot_template_version() {
    local version
    version="$("$1" --version | awk '{print $1}')"
    if [[ "$version" =~ ^([0-9]+\.[0-9]+(\.[0-9]+)?\.(stable|dev[0-9]*|beta[0-9]*|rc[0-9]*)) ]]; then
        printf '%s\n' "${BASH_REMATCH[1]}"
        return
    fi
    printf '%s\n' "$version"
}

resolve_browser_bin() {
    if [[ -n "${BROWSER_BIN:-}" ]]; then
        printf '%s\n' "$BROWSER_BIN"
        return
    fi

    local candidate
    for candidate in brave-browser chromium-browser chromium google-chrome google-chrome-stable microsoft-edge
    do
        if command -v "$candidate" >/dev/null 2>&1; then
            command -v "$candidate"
            return
        fi
    done

    printf '%s\n' "brave-browser"
}

resolve_python_bin() {
    if [[ -n "${PYTHON_BIN:-}" ]]; then
        printf '%s\n' "$PYTHON_BIN"
        return
    fi

    if [[ -x "$repo_root/.venv/bin/python" ]]; then
        printf '%s\n' "$repo_root/.venv/bin/python"
        return
    fi

    if command -v python3 >/dev/null 2>&1; then
        command -v python3
        return
    fi

    if command -v python >/dev/null 2>&1; then
        command -v python
        return
    fi

    printf '%s\n' "$repo_root/.venv/bin/python"
}

godot_bin="$(resolve_godot_bin)"
browser_bin="$(resolve_browser_bin)"
python_bin="$(resolve_python_bin)"

usage() {
    cat >&2 <<EOF
Usage: $0 [/path/to/output-directory]

Environment:
  GODOT_BIN              Godot 4.6.3 binary path. Default: auto-detect local Godot or PATH
  GODOT_EXPORT_DATA_HOME Godot export template data home. Default: $HOME/.local/share
  PYTHON_BIN             Python used by browser preflight. Default: auto-detect venv or python3
  BROWSER_BIN            Desktop browser for flat-web preflight. Default: auto-detect Chromium browser
  M3_REPORT_PATH         Flat-web JSON report path. Default: /tmp/godot-charts-flat-web-report.json
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
    exit 0
fi

if [[ ! -x "$godot_bin" ]]; then
    echo "Godot binary is not executable: $godot_bin" >&2
    echo "Set GODOT_BIN=/path/to/Godot_v4.6.3-stable_linux.x86_64" >&2
    exit 1
fi

if ! command -v "$browser_bin" >/dev/null 2>&1 && [[ ! -x "$browser_bin" ]]; then
    echo "Browser binary not found: $browser_bin" >&2
    echo "Set BROWSER_BIN to a Chromium-compatible browser, for example brave-browser or chromium." >&2
    exit 1
fi

if [[ ! -x "$python_bin" ]]; then
    echo "Python binary is not executable: $python_bin" >&2
    echo "Set PYTHON_BIN=/path/to/python3" >&2
    exit 1
fi

template_version="$(godot_template_version "$godot_bin")"
template_dir="$export_data_home/godot/export_templates/$template_version"
if [[ ! -s "$template_dir/web_nothreads_debug.zip" || ! -s "$template_dir/web_nothreads_release.zip" ]]; then
    echo "Missing Godot Web export templates for $template_version." >&2
    echo "Expected:" >&2
    echo "  $template_dir/web_nothreads_debug.zip" >&2
    echo "  $template_dir/web_nothreads_release.zip" >&2
    echo "Install matching Web export templates, or set GODOT_BIN to a Godot version with templates installed." >&2
    exit 1
fi

output="$(realpath -m "$output")"
if [[ -e "$output" ]]; then
    echo "Refusing to overwrite existing output path: $output" >&2
    echo "Remove it or pass a new output directory." >&2
    exit 1
fi

echo "WebXR headset setup"
echo "Repo: $repo_root"
echo "Godot: $godot_bin"
echo "Godot template version: $template_version"
echo "Browser: $browser_bin"
echo "Python: $python_bin"
echo "Export data home: $export_data_home"
echo "Flat-web report: $report_path"
echo "Candidate output: $output"
echo

echo "1/3 Running desktop flat-web browser preflight..."
GODOT_BIN="$godot_bin" \
GODOT_EXPORT_DATA_HOME="$export_data_home" \
PYTHON_BIN="$python_bin" \
BROWSER_BIN="$browser_bin" \
M3_REPORT_PATH="$report_path" \
"$repo_root/scripts/test-web-browser.sh"

echo
echo "2/3 Running WebXR session contract preflight..."
GODOT_BIN="$godot_bin" \
"$repo_root/scripts/test-webxr-session.sh"

echo
echo "3/3 Building verified WebXR candidate..."
GODOT_BIN="$godot_bin" \
GODOT_EXPORT_DATA_HOME="$export_data_home" \
"$repo_root/scripts/build-web-example.sh" "$output"

cat <<EOF

Setup complete.

Deploy this directory unchanged to a headset-reachable HTTPS URL:
  $output/web/

Keep this report with release evidence:
  $report_path

The HTTPS server must provide:
  - text/html for .html
  - text/javascript for .js
  - application/wasm for .wasm
  - application/octet-stream for .pck
  - a certificate trusted by the headset
  - no mixed HTTP resources
  - WSS, not WS, for optional live endpoints

Next headset steps:
  1. Open the deployed HTTPS URL in the headset browser.
  2. Confirm revision 1 and four rendered points.
  3. Select Frame mode before entering VR.
  4. Enter VR and verify stereo view, controller ray/select, move/commit, exit/re-enter, and reset.
  5. Record the physical row evidence in openspec/changes/rebuild-data-scientist-xr-charting/m3-release-matrix.md.
EOF
