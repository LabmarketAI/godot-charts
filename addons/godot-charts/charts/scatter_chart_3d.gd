@tool
class_name ScatterChart3D
extends PointChart3D

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

@export_group("Mesh Overrides")

## Per-dataset [Mesh] overrides.  Index 0 → first dataset, index 1 → second, etc.
## Takes priority over [member PointChart3D.point_mesh] for any dataset that has an entry.
## An empty entry for a dataset falls back to [member PointChart3D.point_mesh] or the
## built-in sphere.
@export var point_meshes: Array[Mesh] = [] :
	set(v):
		point_meshes = v
		_queue_rebuild()

## Per-dataset [PackedScene] overrides (e.g. Blender-exported .tscn).
## Index 0 → first dataset, index 1 → second, etc.
## Takes priority over [member point_meshes] and [member PointChart3D.point_mesh_scene]
## for any dataset that has an entry.
## If a matching entry exists in [member PointChart3D.point_materials] for this dataset,
## it is applied to all [MeshInstance3D] descendants of the instantiated scene.
@export var point_mesh_scenes: Array[PackedScene] = [] :
	set(v):
		point_mesh_scenes = v
		_queue_rebuild()

@export_group("")

# ---------------------------------------------------------------------------
# Per-dataset mesh resolution overrides
# ---------------------------------------------------------------------------

func _get_point_scene(ds_idx: int) -> PackedScene:
	if ds_idx < point_mesh_scenes.size():
		return point_mesh_scenes[ds_idx]
	return super._get_point_scene(ds_idx)


func _get_point_mesh(ds_idx: int) -> Mesh:
	if ds_idx < point_meshes.size():
		return point_meshes[ds_idx]
	return super._get_point_mesh(ds_idx)

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

	# Find per-axis data extents across all datasets.
	var min_x := INF;  var max_x := -INF
	var min_y := INF;  var max_y := -INF
	var min_z := INF;  var max_z := -INF
	for ds in datasets:
		for pt: Variant in ds.get("points", []) as Array:
			if pt is Vector3:
				var v := pt as Vector3
				min_x = minf(min_x, v.x); max_x = maxf(max_x, v.x)
				min_y = minf(min_y, v.y); max_y = maxf(max_y, v.y)
				min_z = minf(min_z, v.z); max_z = maxf(max_z, v.z)

	if max_x == INF:
		return
	if max_x == min_x: max_x = min_x + 1.0
	if max_y == min_y: max_y = min_y + 1.0
	if max_z == min_z: max_z = min_z + 1.0

	var xs: float = chart_size.x / (max_x - min_x)
	var ys: float = chart_size.y / (max_y - min_y)
	var zs: float = chart_size.x / (max_z - min_z)

	for ds_idx in datasets.size():
		var ds: Dictionary = datasets[ds_idx]
		var pts: Array = ds.get("points", [])
		for pt: Variant in pts:
			if not (pt is Vector3):
				continue
			var v := pt as Vector3
			var pos := Vector3((v.x - min_x) * xs, (v.y - min_y) * ys, (v.z - min_z) * zs)
			var inst := _create_point_instance(ds_idx, pos)
			if inst != null:
				_container.add_child(inst)

	_draw_axes(chart_size.x, chart_size.y, chart_size.x)

	var names: Array = []
	var cols: Array = []
	for ds_idx in datasets.size():
		names.append(datasets[ds_idx].get("name", "Series %d" % ds_idx))
		cols.append(_get_color(ds_idx))
	_draw_legend(names, cols, chart_size.x, chart_size.y)

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
