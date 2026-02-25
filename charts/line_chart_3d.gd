@tool
class_name LineChart3D
extends Chart3D

## A 3D multi-series line chart.
##
## Each dataset is drawn as a poly-line. An optional dot is rendered at every
## data point.  Multiple series are stacked along the Z axis so they remain
## readable when viewed from the front.
##
## [b]Data format[/b]
## [codeblock]
## chart.data = {
##     "labels":   ["Jan", "Feb", "Mar", "Apr"],         # X-axis labels
##     "datasets": [
##         {"name": "Revenue",  "values": [1.0, 3.5, 2.8, 4.2]},
##         {"name": "Expenses", "values": [0.8, 1.2, 2.1, 1.9]},
##     ]
## }
## [/codeblock]
##
## For true 3-D lines supply [code]Vector3[/code] points instead of scalars:
## [codeblock]
## chart.data = {
##     "datasets": [
##         {"name": "Path", "points": [Vector3(0,0,0), Vector3(1,2,1), ...]}
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

## Spacing between series along the Z axis (Godot units).
@export_range(0.0, 5.0, 0.1) var series_z_spacing: float = 1.0 :
	set(v):
		series_z_spacing = v
		_queue_rebuild()

## Show a sphere at each data point.
@export var show_points: bool = true :
	set(v):
		show_points = v
		_queue_rebuild()

## Radius of the point spheres when [member show_points] is enabled.
@export_range(0.01, 0.5, 0.005) var point_radius: float = 0.06 :
	set(v):
		point_radius = v
		_queue_rebuild()

# ---------------------------------------------------------------------------
# Override
# ---------------------------------------------------------------------------

func _rebuild() -> void:
	clear()
	if not is_instance_valid(_container):
		return

	var datasets: Array = data.get("datasets", [])
	var labels: Array  = data.get("labels", [])

	if datasets.is_empty():
		_draw_demo()
		return

	var has_points_mode: bool = not datasets.is_empty() and datasets[0].has("points")

	if has_points_mode:
		_rebuild_vector3_mode(datasets, labels)
	else:
		_rebuild_scalar_mode(datasets, labels)

	emit_signal("data_changed")


func _rebuild_scalar_mode(datasets: Array, labels: Array) -> void:
	var n_datasets: int = datasets.size()
	var n_points: int = 0
	for ds in datasets:
		n_points = maxi(n_points, (ds.get("values", []) as Array).size())

	if n_points < 2:
		return

	var max_val: float = 0.0
	var min_val: float = INF
	for ds in datasets:
		for v in ds.get("values", []) as Array:
			max_val = maxf(max_val, float(v))
			min_val = minf(min_val, float(v))
	if max_val == min_val:
		max_val = min_val + 1.0
	min_val = minf(min_val, 0.0)

	var x_scale: float = 1.0  # 1 unit per category
	var y_scale: float = 1.0 / maxf(max_val - min_val, 0.001)

	for ds_idx in n_datasets:
		var ds: Dictionary = datasets[ds_idx]
		var values: Array = ds.get("values", [])
		var color: Color = _get_color(ds_idx)
		var z: float = ds_idx * series_z_spacing

		_draw_series_2d(values, color, x_scale, y_scale, min_val, z)

	# Axes
	var ax_x: float = (n_points - 1) * x_scale
	var ax_y: float = (max_val - min_val) * y_scale * 1.1
	var ax_z: float = (n_datasets - 1) * series_z_spacing + 0.01
	_draw_axes(ax_x, ax_y, ax_z)

	# X-axis labels
	if show_labels:
		for i in n_points:
			var lbl: String = labels[i] if i < labels.size() else str(i)
			_container.add_child(_make_label(lbl, Vector3(i * x_scale, -0.2, 0)))


func _draw_series_2d(
	values: Array,
	color: Color,
	x_scale: float,
	y_scale: float,
	min_val: float,
	z: float
) -> void:
	var pts: PackedVector3Array = []
	for i in values.size():
		pts.append(Vector3(i * x_scale, (float(values[i]) - min_val) * y_scale, z))

	# Line strip
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, _create_unshaded_material(color))
	for pt in pts:
		mesh.surface_add_vertex(pt)
	mesh.surface_end()
	var line_mi := MeshInstance3D.new()
	line_mi.mesh = mesh
	line_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_container.add_child(line_mi)

	# Data-point spheres
	if show_points:
		var sphere := SphereMesh.new()
		sphere.radius = point_radius
		sphere.height = point_radius * 2.0
		var mat: StandardMaterial3D = _create_material(color)
		for pt in pts:
			var mi := MeshInstance3D.new()
			mi.mesh = sphere
			mi.material_override = mat
			mi.position = pt
			_container.add_child(mi)


func _rebuild_vector3_mode(datasets: Array, _labels: Array) -> void:
	var max_extent: float = 0.0
	for ds in datasets:
		for pt: Variant in ds.get("points", []) as Array:
			if pt is Vector3:
				max_extent = maxf(max_extent, (pt as Vector3).length())

	for ds_idx in datasets.size():
		var ds: Dictionary = datasets[ds_idx]
		var pts: Array = ds.get("points", [])
		var color: Color = _get_color(ds_idx)

		if pts.size() < 2:
			continue

		var mesh := ImmediateMesh.new()
		mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, _create_unshaded_material(color))
		for pt: Variant in pts:
			if pt is Vector3:
				mesh.surface_add_vertex(pt as Vector3)
		mesh.surface_end()
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_container.add_child(mi)

		if show_points:
			var sphere := SphereMesh.new()
			sphere.radius = point_radius
			sphere.height = point_radius * 2.0
			var mat := _create_material(color)
			for pt: Variant in pts:
				if pt is Vector3:
					var smi := MeshInstance3D.new()
					smi.mesh = sphere
					smi.material_override = mat
					smi.position = pt as Vector3
					_container.add_child(smi)

	_draw_axes(max_extent, max_extent, max_extent)


func _draw_demo() -> void:
	data = {
		"labels": ["Jan", "Feb", "Mar", "Apr", "May", "Jun"],
		"datasets": [
			{"name": "Revenue",  "values": [1.2, 2.8, 2.3, 3.9, 3.1, 4.5]},
			{"name": "Expenses", "values": [0.9, 1.4, 2.0, 1.7, 2.4, 2.2]},
		]
	}
