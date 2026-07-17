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

---

## Installation

Godot must find this file at:

```text
res://addons/godot-charts/plugin.cfg
```

Install the release through the Godot Asset Library/package importer, or copy this entire `godot-charts` directory into your project's `addons/` directory. The resulting layout must be:

```text
your-project/
├── project.godot
└── addons/
    └── godot-charts/
        ├── plugin.cfg
        ├── plugin.gd
        ├── charts/
        └── ...
```

Then enable **Godot Charts** under **Project → Project Settings → Plugins**.

If you downloaded the full source repository, copy only `addons/godot-charts/`; do not clone the repository itself into your project's `addons/godot-charts/` path. Doing so creates `addons/godot-charts/addons/godot-charts/`, which Godot will not treat as the intended plugin location.

> **Current runtime note:** this legacy release still contains C# chart implementations and requires a compatible Godot .NET project and build. The planned rebuild will ship as pure typed GDScript for standard Godot and WebXR; consult the installed release notes for its exact requirements.

From a source checkout, the root installer performs the correct copy:

```bash
./install.sh /path/to/your-godot-project
```

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
