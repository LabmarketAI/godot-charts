# M1 contract and replay tests

The recorded session is generated from a real pandas DataFrame and Matplotlib 3D scatter artist. Python dependencies are fixture-only and are not required by the addon.

```bash
python3 -m venv .venv
.venv/bin/python -m pip install -r tools/m1/requirements.txt
.venv/bin/python tools/m1/generate_fixture.py
.venv/bin/python tools/m1/validate_fixtures.py
GODOT_BIN=/path/to/godot bash scripts/test-m1-contract.sh
```

The Godot script creates a temporary standard-Godot project, copies the canonical addon and fixtures into it, and verifies deterministic replay, protocol limits, retained models, batched scatter rendering, bounded Tree-backed tables, and bidirectional selection. A coordinated session test proves revision preservation/reset behavior and exercises deterministic public diagnostics for source/adapter/schema/revision/provenance, protocol/replay, approximations, rejected paths, renderer lifecycle, table window, and linked selection. It does not use the .NET demo or a network connection.
