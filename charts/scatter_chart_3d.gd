@tool
class_name ScatterChart3D
extends Chart3D

## A 3D scatter plot.
##
## Each dataset is a collection of [Vector3] points rendered as small spheres.
## Useful for visualising point clouds, clustering results, or any three-dimensional
## dataset.
##
## [b]Data format[/b]
## [codeblock]
## chart.data = {
##     "datasets": [
##         {
##             "name":   "Group A",
##             "points": [Vector3(0.2, 1.3, 0.5), Vector3(0.8, 0.4, 1.1), ...]
##         },
##         {
##             "name":   "Group B",
##             "points": [Vector3(2.0, 0.6, 0.3), ...]
##         },
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

## Radius of each data-point sphere (Godot units).
@export_range(0.01, 1.0, 0.005) var point_radius: float = 0.08 :
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
	if datasets.is_empty():
		_draw_demo()
		return

	var sphere := SphereMesh.new()
	sphere.radius = point_radius
	sphere.height = point_radius * 2.0
	sphere.radial_segments = 8
	sphere.rings = 4

	var max_extent: float = 0.001
	for ds in datasets:
		for pt: Variant in ds.get("points", []) as Array:
			if pt is Vector3:
				var v := pt as Vector3
				max_extent = maxf(max_extent, absf(v.x))
				max_extent = maxf(max_extent, absf(v.y))
				max_extent = maxf(max_extent, absf(v.z))

	for ds_idx in datasets.size():
		var ds: Dictionary = datasets[ds_idx]
		var pts: Array = ds.get("points", [])
		var color: Color = _get_color(ds_idx)
		var mat: StandardMaterial3D = _create_material(color)

		for pt: Variant in pts:
			if not (pt is Vector3):
				continue
			var mi := MeshInstance3D.new()
			mi.mesh = sphere
			mi.material_override = mat
			mi.position = pt as Vector3
			_container.add_child(mi)

	_draw_axes(max_extent * 1.1, max_extent * 1.1, max_extent * 1.1)
	emit_signal("data_changed")


func _draw_demo() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var pts_a: Array[Vector3] = []
	var pts_b: Array[Vector3] = []
	for _i in 40:
		pts_a.append(Vector3(rng.randf_range(0.1, 1.5), rng.randf_range(0.5, 2.0), rng.randf_range(0.1, 1.5)))
		pts_b.append(Vector3(rng.randf_range(1.0, 2.5), rng.randf_range(0.0, 1.2), rng.randf_range(1.0, 2.5)))
	data = {
		"datasets": [
			{"name": "Cluster A", "points": pts_a},
			{"name": "Cluster B", "points": pts_b},
		]
	}
