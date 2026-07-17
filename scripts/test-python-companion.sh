#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
python_bin="${PYTHON_BIN:-$repo_root/.venv/bin/python}"
PYTHONPATH="$repo_root/python" "$python_bin" -m unittest discover -s "$repo_root/tests/python" -p 'test_*.py' -v
