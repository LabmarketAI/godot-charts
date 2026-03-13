# Godot Charts

A **3D plotting addon for Godot 4**, inspired by [matplotlib](https://matplotlib.org) and [Chart.js](https://www.chartjs.org).
Add beautiful, interactive 3D charts to any Godot project with a few lines of GDScript.

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

### Option A — Git submodule (recommended for staying up to date)

From inside your Godot 4 project's root directory:

```bash
git submodule add https://github.com/LabmarketAI/godot-charts addons/godot-charts
git submodule update --init
```

The checkout lands at `res://addons/godot-charts/`, exactly where Godot expects it.
Enable the plugin under **Project → Project Settings → Plugins → Godot Charts**.

To pull future updates:

```bash
git submodule update --remote addons/godot-charts
```

### Option B — Install script (zero-dependency, CI-friendly)

Clone the repo once, then run `install.sh` to copy the addon into any project:

```bash
git clone https://github.com/LabmarketAI/godot-charts
./godot-charts/install.sh /path/to/your-godot-project
```

This copies `addons/godot-charts/` into the target project and prints a reminder
to enable the plugin.

### Option C — Symlink (best for iterating on the plugin itself)

```bash
# from inside your consumer project
ln -s /path/to/godot-charts/addons/godot-charts addons/godot-charts
```

Edits to the plugin are immediately reflected in the consumer project without
copying any files.

### Option D — From the Godot Asset Library (coming soon)

1. Open your Godot 4 project.
2. Navigate to **AssetLib** and search for *"Godot Charts"*.
3. Click **Download** → **Install**.
4. Enable the plugin under **Project → Project Settings → Plugins**.

### Option E — Manual ZIP download

1. Download the repository as a ZIP file from [GitHub](https://github.com/LabmarketAI/godot-charts).
2. Extract the `addons/godot-charts/` folder from the ZIP.
3. Place it in your project's `addons/` directory.
4. Enable the plugin under **Project → Project Settings → Plugins**.

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

This repository contains **two copies** of the addon to maintain the distributable nature of Godot addons:

- **`addons/godot-charts/`** — Primary addon source (what gets distributed)
- **`demo/addons/godot-charts/`** — Copy used by the demo project

**Local developers should only edit in `addons/godot-charts/`.**
The demo addon copy must match the primary addon source.

**How sync works now:**
1. Edit files in `addons/godot-charts/`.
2. Run `bash scripts/sync-demo-addon.sh` (or `powershell ./scripts/sync-demo-addon.ps1` on Windows).
3. Commit both source and demo addon changes together.
4. CI runs `scripts/check-demo-addon-sync.sh` and fails if folders drift.

This ensures:
- Single source of truth (primary addon location)
- Demo always uses the latest addon code
- Drift is caught automatically in pull requests
- No hidden auto-commit behavior from CI

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
- `Escape`: Toggle mouse capture (release or hide cursor)

#### 2. VR Demo (`main_vr.tscn`) *[requires OpenXR]*
Features a Godot XR Tools rig for exploring the data room in virtual reality.
- **Requirements**: Connected headset, OpenXR runtime active (e.g. SteamVR on Windows, WiVRn on Linux).
- **External addon dependency**: `godot-xr-tools` is treated as an external addon required by the VR demo. Install it under `demo/addons/godot-xr-tools/` (for example from the official repo or Godot Asset Library).
- **Controls**: Standard Godot XR Tools mappings (Left thumbstick for movement/turn, Right trigger for teleport).

The local archive `demo/addons/godot-xr-tools.zip` is for convenience during local setup and is intentionally not tracked by git.

##### Live Desktop Panel

The data room includes a **live desktop capture panel** (slot 8) powered by the [godot-desktop-capture](https://github.com/LabmarketAI/godot-desktop-capture) GDExtension (vendored at `demo/addons/godot-desktop-capture/`). The panel mirrors the host OS desktop in real time onto a 4.8 × 2.7 m screen in the VR environment.

- **Windows**: uses DXGI Desktop Duplication — no extra dependencies.
- **Linux**: uses `xdg-desktop-portal` + PipeWire — a portal permission prompt appears on first run; `libpipewire` and `libdbus` are `dlopen`-ed at runtime (not bundled).

The capture starts automatically when the scene runs (`enabled = true`). To change which monitor is captured, edit the `DesktopCaptureTexture` resource on the `DesktopPanel` node in `data_room.tscn` and set `monitor_index`.

*(Note: There are also standalone, minimal examples for each chart type like `surface_chart.tscn` and `graph_network.tscn`. In those specific minimal scenes, press `Space` to toggle surface mode, or `Tab` to cycle node layout modes.)*

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
