# Godot Charts

A **3D plotting addon for Godot 4**, inspired by [matplotlib](https://matplotlib.org) and [Chart.js](https://www.chartjs.org).  
Add beautiful, interactive 3D charts to any Godot project with a few lines of GDScript.

---

## Chart types

| Class | Description |
|---|---|
| `BarChart3D` | Grouped 3D bar chart |
| `LineChart3D` | Multi-series 3D line chart (scalar or `Vector3` points) |
| `ScatterChart3D` | 3D scatter / point-cloud plot |
| `SurfaceChart3D` | Height-map surface from a 2D grid or a `func(x,z)->float` callable |

---

## Installation

### From the Godot Asset Library (recommended)
1. Open your Godot 4 project.
2. Navigate to **AssetLib** and search for *"Godot Charts"*.
3. Click **Download** → **Install**.
4. Enable the plugin under **Project → Project Settings → Plugins**.

### Manual
1. Copy the `addons/godot_charts/` folder into your project's `addons/` directory.
2. Enable the plugin under **Project → Project Settings → Plugins**.

---

## Quick start

### Bar chart
```gdscript
var chart := BarChart3D.new()
chart.title   = "Monthly Sales"
chart.x_label = "Month"
chart.y_label = "Units"
chart.data = {
    "labels":   ["Jan", "Feb", "Mar", "Apr"],
    "datasets": [
        {"name": "Product A", "values": [120.0, 95.0, 140.0, 180.0]},
        {"name": "Product B", "values": [ 80.0, 110.0, 90.0, 130.0]},
    ]
}
add_child(chart)
```

### Line chart
```gdscript
var chart := LineChart3D.new()
chart.data = {
    "labels":   ["Q1", "Q2", "Q3", "Q4"],
    "datasets": [
        {"name": "Revenue",  "values": [1.2, 3.5, 2.8, 4.2]},
        {"name": "Expenses", "values": [0.9, 1.4, 2.1, 1.9]},
    ]
}
add_child(chart)
```

### Scatter plot
```gdscript
var chart := ScatterChart3D.new()
chart.data = {
    "datasets": [
        {"name": "Group A", "points": [Vector3(0.2,1.3,0.5), Vector3(0.8,0.4,1.1)]},
        {"name": "Group B", "points": [Vector3(2.0,0.6,0.3), Vector3(1.7,1.2,1.9)]},
    ]
}
add_child(chart)
```

### Surface chart (callable)
```gdscript
var chart := SurfaceChart3D.new()
chart.surface_function = func(x: float, z: float) -> float:
    return sin(x * TAU) * cos(z * TAU) * 0.5 + 0.5
chart.grid_cols = 32
chart.grid_rows = 32
add_child(chart)
```

### Surface chart (grid data)
```gdscript
var chart := SurfaceChart3D.new()
chart.grid_data = [
    [0.0, 0.5, 1.0],
    [0.5, 1.5, 0.8],
    [1.0, 0.8, 0.3],
]
add_child(chart)
```

---

## Common properties (all chart types)

| Property | Type | Description |
|---|---|---|
| `title` | `String` | Chart title (billboard label above the chart) |
| `x_label` | `String` | X-axis label |
| `y_label` | `String` | Y-axis label |
| `z_label` | `String` | Z-axis label |
| `colors` | `Array[Color]` | Color palette cycled across datasets |
| `show_axes` | `bool` | Draw X / Y / Z axis lines |
| `show_labels` | `bool` | Draw axis name and category labels |

Charts also emit a **`data_changed`** signal after every redraw.

---

## BarChart3D properties

| Property | Default | Description |
|---|---|---|
| `data` | `{}` | Chart data (see format above) |
| `bar_width` | `0.4` | Width of each bar |
| `bar_depth` | `0.4` | Depth of each bar |
| `group_gap` | `0.6` | Gap between category groups (× bar_width) |
| `series_gap` | `0.1` | Gap between series in a group (× bar_width) |

## LineChart3D properties

| Property | Default | Description |
|---|---|---|
| `data` | `{}` | Chart data |
| `series_z_spacing` | `1.0` | Z offset between series |
| `show_points` | `true` | Draw a sphere at each data point |
| `point_radius` | `0.06` | Radius of data-point spheres |

## ScatterChart3D properties

| Property | Default | Description |
|---|---|---|
| `data` | `{}` | Chart data |
| `point_radius` | `0.08` | Radius of point spheres |

## SurfaceChart3D properties

| Property | Default | Description |
|---|---|---|
| `grid_data` | `[]` | 2-D array of floats |
| `surface_function` | `Callable()` | `func(x,z)->float` callable |
| `grid_cols` | `20` | X resolution (callable mode) |
| `grid_rows` | `20` | Z resolution (callable mode) |
| `x_range` | `Vector2(0,1)` | X domain (callable mode) |
| `z_range` | `Vector2(0,1)` | Z domain (callable mode) |
| `use_height_gradient` | `true` | Color by height |
| `gradient_low` | blue | Color at minimum height |
| `gradient_high` | red | Color at maximum height |

---

## Editor preview

All chart types are annotated with `@tool`, so they render live inside the Godot editor.  
Add a chart node to your scene, set its `data` or `surface_function` property in the Inspector, and the preview updates immediately.

---

## License

MIT – see [LICENSE](LICENSE) for details.
