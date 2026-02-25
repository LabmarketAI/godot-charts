@tool
class_name BarChart3D
extends Chart3D

## A 3D grouped bar chart.
##
## Each dataset produces a row of bars along the X axis.  Multiple datasets are
## offset along the Z axis so bars from different series sit side-by-side.
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

## Gap between category groups expressed as a fraction of bar_width.
@export_range(0.0, 2.0, 0.05) var group_gap: float = 0.6 :
	set(v):
		group_gap = v
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

# ---------------------------------------------------------------------------
# Override
# ---------------------------------------------------------------------------

func _rebuild() -> void:
	clear()
	if not is_instance_valid(_container):
		return

	var datasets: Array = data.get("datasets", [])
	var labels: Array = data.get("labels", [])

	if datasets.is_empty():
		_draw_demo()
		return

	var n_datasets: int = datasets.size()
	var n_categories: int = 0
	for ds in datasets:
		var vals: Array = ds.get("values", [])
		n_categories = maxi(n_categories, vals.size())

	if n_categories == 0:
		return

	# Find the maximum value across all datasets to scale axes.
	var max_val: float = 0.0
	for ds in datasets:
		for v in ds.get("values", []):
			max_val = maxf(max_val, float(v))

	var step: float = bar_width * (n_datasets + series_gap) + group_gap * bar_width
	var group_start: float = -(n_datasets * (bar_width + series_gap * bar_width) - series_gap * bar_width) * 0.5

	for ds_idx in n_datasets:
		var ds: Dictionary = datasets[ds_idx]
		var values: Array = ds.get("values", [])
		var color: Color = _get_color(ds_idx)
		var mat: StandardMaterial3D = _create_material(color)

		var z_offset: float = group_start + ds_idx * (bar_width + series_gap * bar_width)

		for cat_idx in n_categories:
			var val: float = float(values[cat_idx]) if cat_idx < values.size() else 0.0
			if val <= 0.0:
				continue
			var x_pos: float = cat_idx * step
			var height: float = val

			var box := BoxMesh.new()
			box.size = Vector3(bar_width, height, bar_depth)

			var mi := MeshInstance3D.new()
			mi.mesh = box
			mi.material_override = mat
			mi.position = Vector3(x_pos, height * 0.5, z_offset)
			_container.add_child(mi)

	# Axes and category labels
	var axis_x: float = (n_categories - 1) * step + step * 0.5
	_draw_axes(axis_x, max_val * 1.15, 0.01)

	if show_labels:
		for cat_idx in n_categories:
			var lbl_text: String = labels[cat_idx] if cat_idx < labels.size() else str(cat_idx)
			var x_pos: float = cat_idx * step
			_container.add_child(_make_label(lbl_text, Vector3(x_pos, -0.2, 0)))

	emit_signal("data_changed")


func _draw_demo() -> void:
	data = {
		"labels": ["A", "B", "C", "D"],
		"datasets": [
			{"name": "Alpha", "values": [3.0, 5.0, 2.0, 4.0]},
			{"name": "Beta",  "values": [1.5, 3.0, 4.5, 2.5]},
		]
	}
