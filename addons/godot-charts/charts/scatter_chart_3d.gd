@tool
class_name ScatterChart3D
extends Chart3D

const _DEFAULT_POINT_MESH := preload("res://addons/godot-charts/assets/meshes/point_sphere.tres")

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

@export_group("Materials")

## Per-dataset point material overrides.  Index 0 → first dataset, index 1 → second, etc.
## An empty array (default) uses automatic per-dataset colors.
## Assign any [Material] (including [ShaderMaterial]) at the matching index to
## override only that dataset; datasets without an entry keep their auto-color.
@export var point_materials: Array[Material] = [] :
	set(v):
		point_materials = v
		_queue_rebuild()

@export_group("Mesh Overrides")

## Per-dataset [Mesh] overrides.  Index 0 → first dataset, index 1 → second, etc.
## Replaces the default [SphereMesh] for that dataset.
## An empty array (default) uses the built-in [SphereMesh] for every dataset.
## Ignored for any dataset that also has an entry in [member point_mesh_scenes].
@export var point_meshes: Array[Mesh] = [] :
	set(v):
		point_meshes = v
		_queue_rebuild()

## Per-dataset [PackedScene] overrides (e.g. Blender-exported .tscn).
## Index 0 → first dataset, index 1 → second, etc.
## Takes priority over [member point_meshes] for any dataset that has an entry.
## An empty array (default) uses [member point_meshes] or the built-in [SphereMesh].
## If a matching entry exists in [member point_materials] for this dataset, it is applied
## to all [MeshInstance3D] descendants of the instantiated scene.
@export var point_mesh_scenes: Array[PackedScene] = [] :
	set(v):
		point_mesh_scenes = v
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
		var color: Color = _get_color(ds_idx)
		var mat_override: Material = point_materials[ds_idx] if ds_idx < point_materials.size() else null
		var mat: Material = _create_material(color, mat_override)

		# Resolve per-dataset mesh override (scene takes priority over mesh resource).
		var ds_scene: PackedScene = point_mesh_scenes[ds_idx] if ds_idx < point_mesh_scenes.size() else null
		var ds_mesh: Mesh = point_meshes[ds_idx] if ds_idx < point_meshes.size() else null
		var effective_mesh: Mesh = null
		var use_default_mesh: bool = false
		if ds_scene == null:
			if ds_mesh != null:
				effective_mesh = ds_mesh
			else:
				effective_mesh = _DEFAULT_POINT_MESH
				use_default_mesh = true

		for pt: Variant in pts:
			if not (pt is Vector3):
				continue
			var v := pt as Vector3
			var pos := Vector3((v.x - min_x) * xs, (v.y - min_y) * ys, (v.z - min_z) * zs)
			if ds_scene != null:
				var inst: Node3D = ds_scene.instantiate() as Node3D
				if inst != null:
					inst.position = pos
					if mat_override != null:
						_apply_material_to_scene(inst, mat_override)
					_container.add_child(inst)
					_apply_animation(inst)
			else:
				var mi := MeshInstance3D.new()
				mi.mesh = effective_mesh
				mi.material_override = mat
				mi.position = pos
				if use_default_mesh:
					mi.scale = Vector3.ONE * point_radius
				_container.add_child(mi)

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
