# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

**godot-charts** is a Godot 4 addon (`addons/godot-charts/`) providing 3D chart and graph types as GDScript `@tool` nodes. The repo also contains a self-contained demo project (`demo/`) that showcases every chart type.

## Repository structure

```
addons/godot-charts/     ← PRIMARY source (edit here only)
  charts/                ← Chart node implementations
  utils/                 ← Data source helpers
  assets/meshes/         ← Shared .tres mesh resources
  plugin.gd              ← EditorPlugin — registers all custom types
demo/                    ← Godot project for local testing
  addons/godot-charts/   ← Synced copy of the addon (do NOT edit)
  addons/godot-xr-tools/ ← Third-party VR toolkit
  scenes/                ← Demo scenes (main.tscn, main_vr.tscn, data_room.tscn)
tests/                   ← GdUnit4 test suites (.gd)
```

**Only edit `addons/godot-charts/`.** The `demo/addons/godot-charts/` copy is synced automatically by CI via `scripts/sync-demo-addon.sh`. To sync locally: `bash scripts/sync-demo-addon.sh`.

## Running tests

Tests use [GdUnit4](https://github.com/MikeSchulze/gdUnit4). CI builds a temporary harness project and runs them headlessly via the `gdUnit4-action`. There is no local `project.godot` in the repo root for tests — the CI workflow constructs one on the fly.

To run tests locally you need Godot 4.6 and GdUnit4 installed. The test files live in `tests/` and are picked up as `res://tests/` inside the CI harness.

## Running the demo

1. Open Godot 4.6+
2. **File → Open Project** → select `demo/project.godot`
3. Run `demo/scenes/main.tscn` (desktop FPS) or `demo/scenes/main_vr.tscn` (OpenXR)

Desktop controls: `WASD` to move, `1`–`7` to teleport to each chart, `Escape` to toggle mouse capture.

## Architecture

### Chart class hierarchy

```
Node3D
└── Chart3D                        (base: chart_3d.gd)
    ├── ChartFrame3D               (chart_frame_3d.gd) — container/panel, not a chart
    ├── BarChart3D                 (bar_chart_3d.gd)
    ├── LineChart3D                (line_chart_3d.gd)
    ├── ScatterChart3D / PointChart3D / SurfaceChart3D / HistogramChart3D
    └── GraphNetworkChartBase      (graph_network_chart_base.gd)
        ├── GraphNetworkChart2D
        └── GraphNetworkChart3D
```

All chart scripts are annotated `@tool` so they render live in the editor.

### Rendering pattern

Every `Chart3D` subclass owns a `ChartContent` child `Node3D` (`_container`). On each rebuild, `_container` children are freed with `child.free()` (not `queue_free()`) and new geometry is added. Rebuilds are deferred: property setters call `_queue_rebuild()` which sets a flag; `_process()` calls `_rebuild()` on the next frame. Subclasses override `_rebuild()` to emit geometry.

`ChartFrame3D` is not a `Chart3D` — it is a separate panel node that listens for `Chart3D` children added to it and sets their `chart_size` property to fill its inner area.

### Data flow

Charts accept data two ways (source takes priority when both are set):

1. **Inline `data` property** — a `{ "labels": [...], "datasets": [...] }` dictionary assigned directly.
2. **`data_source` property** — a `ChartDataSource` resource. When assigned, the chart connects to `data_source.data_updated` and redraws automatically.

Built-in data sources (`utils/`):
- `DictDataSource` — wraps a static dictionary
- `CSVDataSource` — loads and parses a CSV file
- `StreamDataSource` — rolling FIFO window; call `append_point(series, value)` or `append_frame({...})` from `_process()`
- `GraphNetworkDataSource` — node/edge graph data for network charts

### Key helper methods in `Chart3D`

- `_draw_axes(x, y, z)` — draws RGB axis lines + labels
- `_draw_ticks_y(extent_y, max_val, min_val)` — Y-axis ticks with value labels
- `_draw_grid_xy(extent_x, extent_y)` — horizontal gridlines
- `_draw_legend(names, colors, extent_x, extent_y)` — colored swatches + names
- `_make_line(p0, p1, color)` — returns a `MeshInstance3D` using `ImmediateMesh`
- `_make_label(text, pos)` — billboard `Label3D`
- `_build_rounded_bar_mesh(w, h, d, r)` — procedural rounded-rectangle prism
- `_apply_animation(instance)` — fires `mesh_spawned` signal and plays `spawn_animation`

### Material override pattern

Every geometry helper accepts an optional `mat_override: Material` parameter. Pass `axis_material`, `grid_material`, `tick_material`, or `legend_material` to inject custom `ShaderMaterial`s without subclassing.

## CI

GitHub Actions (`.github/workflows/ci.yml`) runs on pushes/PRs to `main`:
1. **unit-tests** — GdUnit4 against Godot 4.6 stable
2. After a successful push the sync script copies `addons/godot-charts/` into `demo/addons/godot-charts/` and auto-commits
