# Godot Charts 2D

## Multiple Y axes

`LineChart2D` supports overlaid line series with independent Y domains and one
shared X axis:

1. Create `ChartAxis2D` resources with stable `axis_id` values.
2. Assign each `ChartDataset2D.y_axis_id` to one of those ids.
3. Set `LineChart2D.y_axes` in display order.
4. Assign `ChartReferenceLine2D.y_axis_id` when a threshold belongs to a
   particular unit.

The first configured axis normally sits on the left. Additional axes normally
sit on the right and are offset automatically. Compatible series should share
one axis; do not create an axis per line when the units and domain are already
compatible.

```gdscript
var axes: Array[Resource] = [
    ChartAxis2D.new(&"stock", "LITRES", ChartAxis2D.Side.LEFT, Color.BLUE),
    ChartAxis2D.new(&"flow", "L / DAY", ChartAxis2D.Side.RIGHT, Color.ORANGE),
]
var data := ChartData2D.new(PackedStringArray(["D1", "D2"]), [
    ChartDataset2D.new(
        "Stored", PackedFloat32Array([8000, 7200]), Color.BLUE, &"stock"),
    ChartDataset2D.new(
        "Capture", PackedFloat32Array([50, 75]), Color.ORANGE, &"flow"),
])
chart.y_axes = axes
chart.chart_data = data
```

## Longitudinal data integrity

`ChartData2D` uses one shared category axis. Every dataset must have exactly one
value for every label:

```gdscript
assert(data.validation_errors().is_empty())
```

For live or simulation-driven charts, append a complete sample atomically:

```gdscript
data.append_sample("D3", {
    "Stored": 6800.0,
    "Capture": 82.0,
})
```

Dataset labels are the sample keys and must be unique. Category labels must
also be unique. An omitted dataset receives `NAN`, producing a visible line
gap instead of shifting later values onto the wrong category. Unknown dataset
keys and duplicate categories reject the complete append without mutation.

### Design precedents

The implementation follows established open-source chart patterns:

- Plotly binds traces to named axes and overlays independently scaled axes.
- Matplotlib's multiple-spine example shares X, offsets extra right spines, and
  colors axis ticks/titles to match their plotted series.
- Vega-Lite calls this independent scale/axis resolution rather than combining
  unlike values into one domain.
- Apache ECharts reserves layout space for axes and labels to prevent overflow.

Accordingly, `LineChart2D`:

- computes a separate finite/constant/zero-based domain for every axis;
- draws grid lines only for the first axis to avoid contradictory grids;
- colors each axis from its configuration or first assigned series;
- offsets multiple axes and reserves plot margins for them;
- keeps thresholds on their assigned axis; and
- retains the legacy implicit `y` axis when no axes are configured.

Multiple axes increase comparison risk. Prefer one shared axis for compatible
units and small multiples when many independent scales make the plot harder to
read. Explicit axes are a deliberate choice, never inferred from magnitude.

## Current values in legends

Set `show_latest_values` when a live chart must communicate its current value
as well as its trend. The legend then appends the last finite sample for each
visible dataset. This also keeps a new one-sample series informative before a
second point exists to form a line. The option defaults to `false` so ordinary
legends retain their compact labels.
