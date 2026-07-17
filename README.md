# Godot Charts

A **3D plotting addon for Godot 4**, inspired by [matplotlib](https://matplotlib.org) and [Chart.js](https://www.chartjs.org).
Add beautiful, interactive 3D charts to any Godot project with a few lines of GDScript.

**Discord** Chats on the Godot XR Server here: https://discord.gg/nrEbaVFD

**ITCH.io** For videos and releases: https://buddha-314.itch.io/godot-immersive-charting 

---

## What you get out of the box

Godot Charts ships eight 3D chart node types — `BarChart3D`, `LineChart3D`, `ScatterChart3D`, `SurfaceChart3D`, `HistogramChart3D`, `GraphNetworkChart2D`, `GraphNetworkChart3D` — all housed in `ChartFrame3D`, a movable, resizable 3D panel that auto-fits its children. Every chart type is a `@tool` node, so it renders live in the editor as you tweak properties in the Inspector. Data follows a Chart.js-style dictionary (`labels` + `datasets`), and three built-in data sources handle static dictionaries, CSV files, and live rolling windows (`StreamDataSource`). A `MessageBusService` singleton wires the stream sources to a publish/subscribe channel so external systems can push payloads at runtime without touching the chart code directly.

The included demo project (`demo/`) shows every feature in two modes that share the same central "Data Room" scene. In **desktop mode** (`main.tscn`) you walk through the room with WASD/mouse and teleport between charts with the number keys. In **VR mode** (`main_vr.tscn`, requires OpenXR) you explore the same room with a full Godot XR Tools rig. Both modes expose a **diegetic console panel** (F1 / B-Y button) for creating and deleting chart frames at runtime, switching chart types, resizing frames, applying environment presets (daylight / studio / night), controlling the live data stream, and routing individual frames to different data topics. The console also includes a per-frame topic routing system with a manual lock so frames stay pinned to specific data channels even when the bus broadcasts to multiple topics. All layout and binding choices are saved to a workspace profile under `user://workspaces/` and restored on the next run.

In VR, chart frames are fully interactive at runtime: select a chart type widget in the console to arm **placement mode**, then hold the right grip to drag the new frame into world space — the right thumbstick adjusts how far away the frame sits, and a cyan wireframe preview updates live including wall-raycast distance clamping. Releasing the grip finalizes the position. Existing frames can be grabbed with either grip in **move mode** (toggled from the console) and dragged to a new location, with the frame yaw aligning to the controller's forward heading. Transforms persist in the workspace automatically on release. The data room also includes a **live desktop capture panel** powered by the [godot-desktop-capture](https://github.com/LabmarketAI/godot-desktop-capture) GDExtension (DXGI on Windows, PipeWire on Linux), and a **widget library** with a schema validator, spec-to-schema translator, tokenized theme engine with runtime switching, and interactive 3D controls (buttons, sliders, labels) wired to the XR input stack.

---

## Planning Docs

- [Issue 56 widget-library implementation plan](docs/issue-56-widget-library-implementation-plan.md)
- [Issue 56 sub-issue drafts](docs/issue-56-sub-issue-drafts.md)
- [Issue 56 master checklist comment template](docs/issue-56-master-checklist-comment.md)
- [Issue 56 live tracking](docs/issue-56-tracking-live.md)
- [Widget system RFC draft (Phase 0 kickoff)](docs/widget-system-rfc-draft.md)

---

## Chart types

| Class | Description |
|---|---|
| `ChartFrame3D` | Movable, resizable 3D panel that hosts and auto-fits child charts |
| `BarChart3D` | Grouped 3D bar chart |
| `LineChart3D` | Multi-series 3D line chart (scalar or `Vector3` points) |
| `ScatterChart3D` | 3D scatter / point-cloud plot |
| `SurfaceChart3D` | Height-map surface from a 2D grid or a `func(x,z)->float` callable |
| `HistogramChart3D` | Auto-binned histogram built on top of `BarChart3D` |
| `GraphNetworkChart2D` | Force-directed / circular graph network rendered in the XY plane |
| `GraphNetworkChart3D` | Same as 2D but with full 3D node positions (Fibonacci sphere layout) |

---

## Installation

Godot discovers this editor plugin only when `plugin.cfg` has this exact path inside your project:

```text
your-project/
├── project.godot
└── addons/
    └── godot-charts/
        ├── plugin.cfg
        ├── plugin.gd
        └── ...
```

If you see `addons/godot-charts/addons/godot-charts/plugin.cfg`, the repository was installed one directory too deep. Move the inner `godot-charts` directory to `res://addons/godot-charts/`.

> **Current runtime note:** the legacy implementation in this repository still contains C# chart classes and requires a compatible Godot .NET project and build. The active rebuild specification replaces those classes with a pure typed-GDScript addon for standard Godot and WebXR. Check the release notes for the runtime requirements of the version you install.

### Pure-GDScript M1 preview

The architectural-spine preview is packaged from an explicit allowlist and contains no C#, .NET project, NuGet reference, native binary, or demo dependency. Build and test it with:

```bash
./scripts/build-m1-addon.sh /tmp/godot-charts-preview/addons/godot-charts
GODOT_BIN=/path/to/Godot_v4.6.3-stable_linux.x86_64 ./scripts/test-m1-contract.sh
```

The generated directory is the complete preview addon and installs directly at `res://addons/godot-charts/`. The current repository checkout still carries legacy code beside the rebuild for migration evidence; do not package the entire canonical directory as the M1 preview.

For a self-contained recorded-session scene, follow [the M1 five-minute quickstart](examples/m1/README.md).

| M1 dependency | Scope | Required by consumers | Version policy |
|---|---|---|---|
| Standard Godot | Runtime/editor | Yes | 4.6.3 stable floor; no .NET build |
| Matplotlib | Fixture generation | No | Development-only, pinned in `tools/m1/requirements.txt` |
| pandas | Fixture generation | No | Development-only, pinned in `tools/m1/requirements.txt` |
| Python JSON Schema | Contract validation | No | Development-only, pinned in `tools/m1/requirements.txt` |

### Optional live WebSocket transport

The preview addon includes `WebSocketSessionClient`, an optional standard-Godot adapter that feeds the exact same normalized envelopes into the replay-tested session consumer. It uses Godot's built-in `WebSocketPeer`; consumers do not need a native extension, .NET, or a third-party Godot plugin. The adapter requires a handshake as the first envelope, rejects cross-session messages, enforces bounded messages and polling, redacts endpoint paths and queries from its trace snapshot, and keeps authentication outside the plot contract.

Run the localhost integration fixture with:

```bash
python -m venv .venv
.venv/bin/python -m pip install -r tools/live/requirements.txt
GODOT_BIN=/path/to/Godot_v4.6.3-stable_linux.x86_64 \
  PYTHON_BIN=.venv/bin/python ./scripts/test-live-transport.sh
```

The Python `websockets` package is pinned for the fixture publisher only. It is not an addon runtime dependency. Authentication, remote workspace discovery, and Jupyter kernel selection remain separate follow-up integrations.

### Python companion preview

The repository now contains the first reusable companion API under `python/godot_charts_companion`. A notebook or trusted Python process supplies a Matplotlib 3D figure, its explicit pandas DataFrame, stable index identities, and column mappings. The adapter reads public Matplotlib axes state and emits the normalized plot envelope consumed by Godot:

```python
from godot_charts_companion import (
    Scatter3DMapping,
    handshake_message,
    matplotlib_scatter_message,
    serve_messages,
)

plot = matplotlib_scatter_message(
    figure,
    dataframe,
    Scatter3DMapping("year", "sites", "enrolled", "phase"),
    session_id="session-notebook",
    sequence=1,
    plot_id="plot-trials",
    dataset_id="dataset-trials",
    color_map={"I": "#3b82f6", "II": "#f59e0b", "III": "#10b981"},
)
await serve_messages([handshake_message("session-notebook"), plot])
```

Install the preview companion from the repository with `python -m pip install ./python`. It supports only the explicit 3D scatter/DataFrame slice today. It does not deserialize pickle, execute callbacks or code strings, discover notebook variables, or handle Jupyter authentication.

### Release archive or Godot Asset Library — preferred

Release and Asset Library packages contain the canonical `addons/godot-charts/` tree. In Godot, use **AssetLib → Import** for a downloaded package, or merge the package's `addons/` directory into the root of your project. Then enable **Godot Charts** under **Project → Project Settings → Plugins**.

This matches Godot's documented addon convention and avoids repository nesting.

### Clone and install — source builds

Clone the repository outside your consumer project's `addons/` directory, then use the installer to copy only the canonical addon:

```bash
git clone https://github.com/LabmarketAI/godot-charts.git
./godot-charts/install.sh /path/to/your-godot-project
```

This produces `/path/to/your-godot-project/addons/godot-charts/plugin.cfg`.

### Manual source copy

```bash
mkdir -p /path/to/your-godot-project/addons
cp -R godot-charts/addons/godot-charts /path/to/your-godot-project/addons/
```

Copy the directory named `godot-charts`, not the repository root.

### Development symlink

On platforms where directory symlinks are appropriate:

```bash
mkdir -p /path/to/your-godot-project/addons
ln -s /absolute/path/to/godot-charts/addons/godot-charts \
  /path/to/your-godot-project/addons/godot-charts
```

Do **not** add this entire repository as a submodule at `addons/godot-charts`; this repository also contains `demo/`, `tests/`, and planning material, so that command creates the invalid extra directory layer. Consumers that require submodule pinning should place the repository under a vendor directory and create their own copy/symlink step, or consume a packaged release.

---

## Local Development & Demo Project

A self-contained Godot 4 demo project lives in the `demo/` folder at the root of this
repository. It showcases every chart type with interactive scenes and sample data.
The demo includes a unified "Data Room" environment accessible via both a standard **desktop first-person controller** and an **OpenXR virtual reality (VR)** setup.

**Note:** The demo is excluded from Asset Library downloads via `.gitattributes` but is 
available for local development and testing when you clone the repository.

### Running the demo locally

#### Step 1: Clone the repository

**On Linux/macOS:**
```bash
git clone https://github.com/LabmarketAI/godot-charts
cd godot-charts
```

**On Windows (PowerShell / CMD):**
```cmd
git clone https://github.com/LabmarketAI/godot-charts
cd godot-charts
```

**On Windows (WSL / Git Bash):**
```bash
git clone https://github.com/LabmarketAI/godot-charts
cd godot-charts
```

#### Step 2: Open the demo in Godot

All platforms follow the same steps:

1. Launch **Godot 4.6+**
2. Click **Open Project** (or go to **File → Open Project**)
3. Navigate to the `godot-charts/demo/` folder
4. Select `project.godot` and click **Open**
5. Click **Open & Edit** (or double-click the project)

The addon is automatically available at `res://addons/godot-charts/`:
- Changes to the addon source code are immediately reflected in the demo
- All chart types are editable in both the editor and via code
- The demo works identically on Windows, Linux, and macOS

### Repository structure & development workflow

This repository currently contains a canonical addon and a legacy demo mirror:

- **`addons/godot-charts/`** — canonical source and the only directory packaged for consumers
- **`demo/addons/godot-charts/`** — generated mirror required because `demo/` is a separate Godot project

Never edit the demo mirror directly. After changing the canonical addon, synchronize it locally before running or committing demo work:

```bash
bash scripts/sync-demo-addon.sh
bash scripts/check-demo-addon-sync.sh
```

CI verifies that the mirror matches. The rebuild will prefer a generated or linked test fixture so duplicated addon source does not remain a long-term architectural requirement.

### Installing addon updates in development

If you're iterating on the addon code and want changes to be immediately visible:

**Recommended approach (all platforms):**
- Edit files directly in `addons/godot-charts/` (either in VS Code or Godot's built-in editor)
- Save changes
- Return to Godot; the addon recompiles automatically

**For consuming projects (copy addon to another project):**

**On Linux/macOS:**
```bash
./install.sh /path/to/your-project
```

**On Windows (PowerShell):**
```powershell
# Option 1: Use WSL (if installed)
wsl ./install.sh /mnt/c/path/to/your-project

# Option 2: Use robocopy (copy command with full directory tree)
robocopy addons\godot-charts C:\path\to\your-project\addons\godot-charts /E

# Option 3: Manual copy via File Explorer
# Navigate to addons/godot-charts, copy folder, paste into your-project/addons/
```

**On Windows (CMD):**
```cmd
REM Option 1: Use robocopy
robocopy addons\godot-charts C:\path\to\your-project\addons\godot-charts /E

REM Option 2: Use xcopy
xcopy addons\godot-charts C:\path\to\your-project\addons\godot-charts /E /I /Y

REM Option 3: Manual copy via File Explorer
REM Navigate to addons/godot-charts, copy folder, paste into your-project/addons/
```

**On Windows (Git Bash):**
```bash
# If you have Git Bash installed, you can use the same bash syntax as Linux
./install.sh /c/path/to/your-project
```

### Building demos or examples into your own project

If you want a self-contained example project for distribution or sharing:
- Copy the `demo/scenes/` folder and `demo/addons/godot-charts/` into your project
- Or follow the **Quickstart** section below to build interactive examples from scratch

### Demo Scenes & Navigation

The `demo/scenes/` folder contains two main entry points that both instantiate the same central 3D data room (`data_room.tscn`):

#### 1. Desktop Demo (`main.tscn`)
Features a standard first-person controller to walk around the chart displays.
- `W` `A` `S` `D` (or Arrows): Walk and strafe
- **Mouse**: Look around
- `1` – `7`: Instantly teleport to the viewing position for a specific chart
- `F1`: Toggle the diegetic console panel (Phase 1 scaffold)
- `Escape`: Toggle mouse capture (release or hide cursor)

Diegetic console workspace persistence:
- Workspaces are saved under `user://workspaces/`
- The active workspace is remembered between runs
- The console defaults to **hidden** on first run (`F1` to open)
- Phase 4 scaffold: use the console to create/delete runtime frames, set chart type/size, set frame visual presets, choose per-frame binding mode (`demo_static` or `demo_stream`), and apply environment presets (`daylight`, `studio`, `night`)
- Data stream control: the console includes explicit `Start Stream`, `Stop Stream`, and `Toggle Stream` controls for the demo message bus. The bus defaults to started on scene load and can be toggled repeatedly during runtime.
- Desktop runtime frames (`chart_type = desktop`) can be assigned to specific host windows so multiple in-world frames can show different applications simultaneously
- Runtime frame transforms, chart assignments, binding modes, frame presets, and desktop window selections are saved with the active workspace profile
- Console now surfaces environment-application status (ready/partial/missing nodes) when applying presets
- Environment presets now attempt HDRI sky assets first from `res://assets/hdri/{daylight|studio|night}.{hdr|exr|ktx}` and fall back to color sky when assets are unavailable

#### 2. VR Demo (`main_vr.tscn`) *[requires OpenXR]*
Features a Godot XR Tools rig for exploring the data room in virtual reality.
- **Requirements**: Connected headset, OpenXR runtime active (e.g. SteamVR on Windows, WiVRn on Linux).
- **External addon dependency**: `godot-xr-tools` is treated as an external addon required by the VR demo. Install it under `demo/addons/godot-xr-tools/` (for example from the official repo or Godot Asset Library).
- **Quest keyboard passthrough (optional)**: The demo now depends on `godot-openxr-vendors` (submodule at `demo/addons/godot-openxr-vendors/`) to expose Meta keyboard tracking support.
- **Controls**: Standard Godot XR Tools mappings (Left thumbstick for movement/turn, Right trigger for teleport). Press `B/Y` to toggle the keyboard passthrough window when supported. Press `F1` to toggle the diegetic console scaffold.

Diegetic console workspace persistence:
- Workspaces are saved under `user://workspaces/`
- The active workspace is remembered between runs
- The console defaults to **hidden** on first run (`F1` to open)
- Phase 4 scaffold: use the console to create/delete runtime frames, set chart type/size, set frame visual presets, choose per-frame binding mode (`demo_static` or `demo_stream`), and apply environment presets (`daylight`, `studio`, `night`)
- Data stream control: the console includes explicit `Start Stream`, `Stop Stream`, and `Toggle Stream` controls for the demo message bus. The bus defaults to started on scene load and can be toggled repeatedly during runtime.
- Desktop runtime frames (`chart_type = desktop`) can be assigned to specific host windows so multiple in-world frames can show different applications simultaneously
- Runtime frame transforms, chart assignments, binding modes, frame presets, and desktop window selections are saved with the active workspace profile
- Console now surfaces environment-application status (ready/partial/missing nodes) when applying presets
- Environment presets now attempt HDRI sky assets first from `res://assets/hdri/{daylight|studio|night}.{hdr|exr|ktx}` and fall back to color sky when assets are unavailable

Keyboard passthrough behavior:
- On Quest runtimes exposing `XR_FB_keyboard_tracking`, `main_vr.tscn` starts keyboard tracking automatically so the physical keyboard can appear via passthrough.
- On non-Meta runtimes (for example ALVR/WiVRn PC runtimes), the feature is a silent no-op.

Upstream references (passthrough and keyboard tracking context):
- `godot_openxr_vendors` keyboard-related request: [#77](https://github.com/GodotVR/godot_openxr_vendors/issues/77)
- `godot_openxr_vendors` passthrough issues: [#465](https://github.com/GodotVR/godot_openxr_vendors/issues/465), [#239](https://github.com/GodotVR/godot_openxr_vendors/issues/239), [#190](https://github.com/GodotVR/godot_openxr_vendors/issues/190)
- `godot-xr-tools` passthrough/MR issues: [#552](https://github.com/GodotVR/godot-xr-tools/issues/552), [#562](https://github.com/GodotVR/godot-xr-tools/issues/562)
- Core Godot OpenXR passthrough reference: [godotengine/godot#81338](https://github.com/godotengine/godot/issues/81338)

Current status note:
- In the tested `godot_openxr_vendors` line, no `XRFbKeyboardTrackingExtension` wrapper class is exposed to Godot scripts, so keyboard-window passthrough is not currently available through that class path.

The local archive `demo/addons/godot-xr-tools.zip` is for convenience during local setup and is intentionally not tracked by git.

##### Live Desktop Panel

The data room includes a **live desktop capture panel** (slot 8) powered by the [godot-desktop-capture](https://github.com/LabmarketAI/godot-desktop-capture) GDExtension (vendored at `demo/addons/godot-desktop-capture/`). The panel mirrors the host OS desktop in real time onto a 4.8 × 2.7 m screen in the VR environment.

- **Windows**: uses DXGI Desktop Duplication — no extra dependencies.
- **Linux**: uses `xdg-desktop-portal` + PipeWire — a portal permission prompt appears on first run; `libpipewire` and `libdbus` are `dlopen`-ed at runtime (not bundled).

The capture starts automatically when the scene runs (`enabled = true`). To change which monitor is captured, edit the `DesktopCaptureTexture` resource on the `DesktopPanel` node in `data_room.tscn` and set `monitor_index`.

*(Note: There are also standalone, minimal examples for each chart type like `surface_chart.tscn`, `graph_network.tscn`, `circuit_chart.tscn`, and `qiskit_circuit.tscn`. In those specific minimal scenes, press `Space` to toggle surface mode, or `Tab` to scrub/cycle the visualization mode.)*

### Troubleshooting local development

#### "Parse Error: Could not resolve script" on Windows

**Symptom:** Godot fails to load the plugin with errors like:
```
Parse Error: Could not resolve script "res://addons/godot-charts/charts/graph_network_chart_2d.gd"
```

**Cause:** This typically occurs on Windows when GDScript files have CRLF (Windows-style) line endings instead of LF (Unix-style).

**Solution:** Normalize line endings to LF:

```bash
# On WSL / Git Bash, from the root of the repository
find addons/godot-charts -type f \( -name "*.gd" -o -name "*.tscn" -o -name "*.tres" \) -exec dos2unix {} +
```

Or on Windows CMD (if you have Git installed):
```cmd
git config core.autocrlf false
git add -A
git commit -m "Normalize line endings to LF"
```

Then restart Godot — the addon should load without errors.

**Prevention:** The repository's `.gitattributes` file ensures line endings are normalized for future commits on all platforms.

#### Demo addon out of sync with primary addon

**Symptom:** You edited `addons/godot-charts/` but changes don't appear in the demo.

**Cause:** The sync script hasn't been run yet (it runs automatically in CI/CD on push).

**Solution (local sync):**
```bash
# From the repository root
bash scripts/sync-demo-addon.sh
```

This copies all changes from `addons/godot-charts/` to `demo/addons/godot-charts/`.

---

## Quickstart

This walkthrough creates a bar chart inside a frame from scratch.
Follow along in code, or do the equivalent steps in the Godot editor.

### Step 1 — Enable the plugin

Go to **Project → Project Settings → Plugins** and enable **Godot Charts**.
The five chart node types will now appear in the **Add Node** dialog.

### Step 2 — Create a scene and add a ChartFrame3D

`ChartFrame3D` is a thin 3D panel (depth `0.1` by default) that acts as a
movable, resizable container for your charts.  Think of it as the figure window
in matplotlib.

In the editor: add a `Node3D` as your scene root, then add a `ChartFrame3D`
child.  Set its `size` in the Inspector (default `Vector2(4, 3)` — width × height
in Godot units).

In code:

```gdscript
extends Node3D

func _ready() -> void:
    var frame := ChartFrame3D.new()
    frame.size = Vector2(6.0, 4.0)   # width × height in Godot units
    frame.position = Vector3(0, 0, 0) # move it anywhere in the scene
    add_child(frame)
```

### Step 3 — Add a chart as a child of the frame

Any `Chart3D` subclass added as a **direct child** of `ChartFrame3D` is
automatically positioned and scaled to fill the frame's inner area.

```gdscript
    var chart := BarChart3D.new()
    frame.add_child(chart)  # ChartFrame3D fits the chart automatically
```

Or in the editor: drag a `BarChart3D` node onto `ChartFrame3D` in the Scene
panel.  The chart immediately previews inside the frame (all types use `@tool`).

### Step 4 — Supply data

Data follows a `{ "labels": [...], "datasets": [...] }` dictionary structure
modelled on Chart.js.  Assigning `data` triggers an instant redraw.

```gdscript
    chart.title   = "Monthly Sales"
    chart.x_label = "Month"
    chart.y_label = "Units"
    chart.data = {
        "labels": ["Jan", "Feb", "Mar", "Apr"],
        "datasets": [
            {"name": "Product A", "values": [120.0,  95.0, 140.0, 180.0]},
            {"name": "Product B", "values": [ 80.0, 110.0,  90.0, 130.0]},
        ],
    }
```

### Step 5 — Position the camera

Charts are built in Godot-unit space with the origin at the bottom-left corner.
A `Camera3D` at roughly `(frame_width/2, frame_height/2, 8)` looking toward the
origin gives a good front-on view of a `6×4` frame:

```gdscript
    var cam := Camera3D.new()
    cam.position = Vector3(3.0, 2.0, 8.0)
    add_child(cam)
```

### Step 6 — React to data changes

Every chart emits `data_changed` after each redraw:

```gdscript
    chart.data_changed.connect(func(): print("chart updated"))
```

`ChartFrame3D` emits `resized(new_size: Vector2)` when its size changes:

```gdscript
    frame.resized.connect(func(s): print("frame is now ", s))
```

### Complete example

```gdscript
extends Node3D

func _ready() -> void:
    # Frame — the movable container
    var frame := ChartFrame3D.new()
    frame.size = Vector2(6.0, 4.0)
    add_child(frame)

    # Chart — auto-fitted to the frame's inner area
    var chart := BarChart3D.new()
    chart.title   = "Monthly Sales"
    chart.x_label = "Month"
    chart.y_label = "Units"
    chart.data = {
        "labels": ["Jan", "Feb", "Mar", "Apr"],
        "datasets": [
            {"name": "Product A", "values": [120.0,  95.0, 140.0, 180.0]},
            {"name": "Product B", "values": [ 80.0, 110.0,  90.0, 130.0]},
        ],
    }
    frame.add_child(chart)

    # Camera
    var cam := Camera3D.new()
    cam.position = Vector3(3.0, 2.0, 8.0)
    cam.look_at(Vector3(3.0, 2.0, 0.0))
    add_child(cam)
```

---

## All chart types — data examples

### Bar chart

```gdscript
var chart := BarChart3D.new()
chart.data = {
    "labels":   ["Jan", "Feb", "Mar", "Apr"],
    "datasets": [
        {"name": "Product A", "values": [120.0, 95.0, 140.0, 180.0]},
        {"name": "Product B", "values": [ 80.0, 110.0, 90.0, 130.0]},
    ],
}
```

### Line chart

```gdscript
var chart := LineChart3D.new()
chart.data = {
    "labels":   ["Q1", "Q2", "Q3", "Q4"],
    "datasets": [
        {"name": "Revenue",  "values": [1.2, 3.5, 2.8, 4.2]},
        {"name": "Expenses", "values": [0.9, 1.4, 2.1, 1.9]},
    ],
}
```

### Scatter plot

```gdscript
var chart := ScatterChart3D.new()
chart.data = {
    "datasets": [
        {"name": "Group A", "points": [Vector3(0.2, 1.3, 0.5), Vector3(0.8, 0.4, 1.1)]},
        {"name": "Group B", "points": [Vector3(2.0, 0.6, 0.3), Vector3(1.7, 1.2, 1.9)]},
    ],
}
```

Point coordinates are automatically normalized to the frame's inner area —
you supply raw data values, the chart handles the scaling.

### Surface chart (callable)

```gdscript
var chart := SurfaceChart3D.new()
chart.surface_function = func(x: float, z: float) -> float:
    return sin(x * TAU) * cos(z * TAU) * 0.5 + 0.5
chart.grid_cols = 32
chart.grid_rows = 32
```

### Surface chart (grid data)

```gdscript
var chart := SurfaceChart3D.new()
chart.grid_data = [
    [0.0, 0.5, 1.0],
    [0.5, 1.5, 0.8],
    [1.0, 0.8, 0.3],
]
```

---

## Reference

### ChartFrame3D properties

| Property | Default | Description |
|---|---|---|
| `size` | `Vector2(4, 3)` | Width × height of the frame in Godot units |
| `frame_depth` | `0.1` | Thickness of the 3D background panel |
| `background_color` | dark grey | Panel background color |
| `border_color` | light grey | Border outline color |
| `show_background` | `true` | Show/hide the background panel |
| `show_border` | `true` | Show/hide the border outline |
| `padding` | `0.15` | Space between frame edge and chart content |

`resize(new_size: Vector2)` — programmatic resize (same as setting `size`).
`get_inner_size() -> Vector2` — returns the usable inner area after padding.
Signal: `resized(new_size: Vector2)`

### Common properties (all chart types)

| Property | Type | Description |
|---|---|---|
| `chart_size` | `Vector2` | Target bounding box; set automatically by `ChartFrame3D` |
| `title` | `String` | Chart title (billboard label above the chart) |
| `x_label` | `String` | X-axis label |
| `y_label` | `String` | Y-axis label |
| `z_label` | `String` | Z-axis label |
| `colors` | `Array[Color]` | Color palette cycled across datasets |
| `show_axes` | `bool` | Draw X / Y / Z axis lines |
| `show_labels` | `bool` | Draw axis name and category labels |

Signal: `data_changed` — emitted after every redraw.

### BarChart3D properties

| Property | Default | Description |
|---|---|---|
| `data` | `{}` | Chart data dictionary |
| `bar_width` | `0.4` | Max width of each bar (capped to fit category slot) |
| `bar_depth` | `0.4` | Depth of each bar along the Z axis |
| `series_gap` | `0.1` | Gap between datasets within a group (× bar_width) |

### LineChart3D properties

| Property | Default | Description |
|---|---|---|
| `data` | `{}` | Chart data dictionary |
| `series_z_spacing` | `1.0` | Z offset between multiple series |
| `show_points` | `true` | Draw a sphere at each data point |
| `point_radius` | `0.06` | Radius of data-point spheres |

### ScatterChart3D properties

| Property | Default | Description |
|---|---|---|
| `data` | `{}` | Chart data dictionary |
| `point_radius` | `0.08` | Radius of point spheres |

### SurfaceChart3D properties

| Property | Default | Description |
|---|---|---|
| `grid_data` | `[]` | 2-D array of floats (rows × columns) |
| `surface_function` | `Callable()` | `func(x, z) -> float` callable; overrides `grid_data` |
| `grid_cols` | `20` | X resolution in callable mode |
| `grid_rows` | `20` | Z resolution in callable mode |
| `x_range` | `Vector2(0, 1)` | X domain in callable mode |
| `z_range` | `Vector2(0, 1)` | Z domain in callable mode |
| `use_height_gradient` | `true` | Color surface by height |
| `gradient_low` | blue | Color at minimum height |
| `gradient_high` | red | Color at maximum height |

---

## Editor preview

All chart types are annotated with `@tool`, so they render live in the Godot
editor.  Add a `ChartFrame3D` to your scene, nest a chart inside it, and the
preview updates in real time as you adjust properties in the Inspector.

---

## License

MIT – see [LICENSE](LICENSE) for details.
