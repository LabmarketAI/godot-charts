@tool
class_name BarChart3D
extends Chart3D

## A 3D grouped bar chart.
##
## Categories are distributed evenly along the X axis.  Within each category
## slot, bars from different datasets are placed side-by-side in X (matplotlib-
## style grouping), so the chart reads clearly from any viewing angle.
## All bars share the same Z depth — bar_depth controls thickness toward +Z.
##
## [b]Data format[/b]
## [codeblock]
## chart.data = {
##     "labels":   ["Cat A", "Cat B", "Cat C"],          # X-axis category names
##     "datasets": [
##         {"name": "Series 1", "values": [3.0, 5.0, 2.0]},
##         {"name": "Series 2", "values": [1.0, 4.0, 6.0]},
##     ]
## }
## [/codeblock]

# ---------------------------------------------------------------------------
# Exported properties
# ---------------------------------------------------------------------------

## Chart data dictionary.  Assigning triggers an immediate redraw.
@export var data: Dictionary = {} :
	set(v):
		data = v
		_queue_rebuild()

## Width of each individual bar (in Godot units).
@export_range(0.05, 2.0, 0.01) var bar_width: float = 0.4 :
	set(v):
		bar_width = v
		_queue_rebuild()

## Gap between datasets within a group, expressed as a fraction of bar_width.
@export_range(0.0, 1.0, 0.05) var series_gap: float = 0.1 :
	set(v):
		series_gap = v
		_queue_rebuild()

## Depth of each bar (along the Z axis, in Godot units).
@export_range(0.05, 2.0, 0.01) var bar_depth: float = 0.4 :
	set(v):
		bar_depth = v
		_queue_rebuild()

@export_group("Materials")

## Per-dataset material overrides.  Index 0 → first dataset, index 1 → second, etc.
## An empty array (default) uses automatic per-dataset colors.
## Assign any [Material] (including [ShaderMaterial]) at the matching index to
## override only that dataset; datasets without an entry keep their auto-color.
@export var bar_materials: Array[Material] = [] :
	set(v):
		bar_materials = v
		_queue_rebuild()

@export_group("Mesh Overrides")

## Replace each bar's built-in [BoxMesh] with an instance of this [PackedScene].
## The scene root must be a [Node3D]; it will be scaled to (bar_width, bar_height, bar_depth).
## When null (default) the built-in [BoxMesh] is used.
## If a matching entry exists in [member bar_materials] for this dataset, it is applied
## to all [MeshInstance3D] descendants of the instantiated scene.
@export var bar_mesh_scene: PackedScene = null :
	set(v):
		bar_mesh_scene = v
		_queue_rebuild()

## Radius of the rounded corners on each bar (Godot units).
## 0.0 (default) = sharp BoxMesh corners.  Clamped to half the smaller of
## [member bar_width] / [member bar_depth] so the geometry is always valid.
## Ignored when [member bar_mesh_scene] is set.
@export_range(0.0, 0.5, 0.005) var bar_corner_radius: float = 0.0 :
	set(v):
		bar_corner_radius = v
		_queue_rebuild()

@export_group("")

# ---------------------------------------------------------------------------
# Override
# ---------------------------------------------------------------------------

func _rebuild() -> void:
	clear()
	if not is_instance_valid(_container):
		return

	var d: Dictionary = _get_source_data() if data_source != null else data
	var datasets: Array = d.get("datasets", [])
	if datasets.is_empty():
		_draw_demo()
		return

	_render_bar_data(d)
	emit_signal("data_changed")


## Renders bar geometry from [param d] (a dict with "labels" and "datasets").
## Called by [method _rebuild] and by [HistogramChart3D] with computed bin data.
func _render_bar_data(d: Dictionary) -> void:
	var datasets: Array = d.get("datasets", [])
	var labels: Array = d.get("labels", [])

	var n_datasets: int = datasets.size()
	var n_categories: int = 0
	for ds in datasets:
		n_categories = maxi(n_categories, (ds.get("values", []) as Array).size())

	if n_categories == 0:
		return

	var max_val: float = 0.0
	for ds in datasets:
		for v in ds.get("values", []):
			max_val = maxf(max_val, float(v))

	if max_val == 0.0:
		return

	# Distribute categories evenly across chart_size.x; scale heights to chart_size.y.
	var x_step: float = chart_size.x / float(n_categories)
	var y_scale: float = chart_size.y / max_val

	# Each category slot is divided equally among datasets (side-by-side in X).
	# series_gap is the fraction of each sub-slot that becomes empty space.
	var bar_pitch: float = (x_step * 0.85) / float(n_datasets)
	var bw: float = minf(bar_width, bar_pitch * (1.0 - series_gap))
	bw = maxf(bw, 0.02)

	for ds_idx in n_datasets:
		var ds: Dictionary = datasets[ds_idx]
		var values: Array = ds.get("values", [])
		var color: Color = _get_color(ds_idx)
		# Use per-dataset override when provided; fall back to auto-color (Issue #4).
		var override: Material = bar_materials[ds_idx] if ds_idx < bar_materials.size() else null
		var mat: Material = _create_material(color, override)

		for cat_idx in n_categories:
			var val: float = float(values[cat_idx]) if cat_idx < values.size() else 0.0
			if val <= 0.0:
				continue
			# Left edge of the 85%-wide group inside this category slot.
			var group_left: float = float(cat_idx) * x_step + x_step * 0.075
			var x_center: float = group_left + (float(ds_idx) + 0.5) * bar_pitch
			var bar_h: float = val * y_scale

			var bar_pos := Vector3(x_center, bar_h * 0.5, bar_depth * 0.5)
			if bar_mesh_scene != null:
				var inst: Node3D = bar_mesh_scene.instantiate() as Node3D
				if inst != null:
					inst.scale = Vector3(bw, bar_h, bar_depth)
					inst.position = bar_pos
					if override != null:
						_apply_material_to_scene(inst, override)
					_container.add_child(inst)
					_apply_animation(inst)
			else:
				var bar_mesh: Mesh
				if bar_corner_radius > 0.0:
					bar_mesh = _build_rounded_bar_mesh(bw, bar_h, bar_depth, bar_corner_radius)
				else:
					var box := BoxMesh.new()
					box.size = Vector3(bw, bar_h, bar_depth)
					bar_mesh = box
				var mi := MeshInstance3D.new()
				mi.mesh = bar_mesh
				mi.material_override = mat
				# All bars sit at Z = bar_depth * 0.5 so the front face is at Z = 0.
				mi.position = bar_pos
				_container.add_child(mi)

	_draw_grid_xy(chart_size.x, chart_size.y)
	_draw_axes(chart_size.x, chart_size.y, 0.01)
	_draw_ticks_y(chart_size.y, max_val)

	if show_labels:
		for cat_idx in n_categories:
			var lbl_text: String = labels[cat_idx] if cat_idx < labels.size() else str(cat_idx)
			var x_center: float = (float(cat_idx) + 0.5) * x_step
			_container.add_child(_make_label(lbl_text, Vector3(x_center, -0.2, 0)))

	var names: Array = []
	var cols: Array = []
	for ds_idx in n_datasets:
		names.append(datasets[ds_idx].get("name", "Series %d" % ds_idx))
		cols.append(_get_color(ds_idx))
	_draw_legend(names, cols, chart_size.x, chart_size.y)


func _draw_demo() -> void:
	data = {
		"labels": ["A", "B", "C", "D"],
		"datasets": [
			{"name": "Alpha", "values": [3.0, 5.0, 2.0, 4.0]},
			{"name": "Beta",  "values": [1.5, 3.0, 4.5, 2.5]},
		]
	}
