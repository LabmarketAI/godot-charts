@tool
class_name PointChart3D
extends Chart3D

## Abstract base class for charts that render data as point instances.
##
## Provides shared point geometry properties ([member point_radius],
## [member point_materials], [member point_textures], [member point_mesh],
## [member point_mesh_scene]) and the [method _create_point_instance] helper
## that encapsulates the full scene → mesh → default-sphere resolution.
##
## Sub-classes override [method _get_point_scene] and [method _get_point_mesh]
## to supply per-dataset overrides on top of the single-override properties
## defined here.
##
## Concrete sub-classes: [ScatterChart3D], [LineChart3D].

const _DEFAULT_POINT_MESH := preload("res://addons/godot-charts/assets/meshes/point_sphere.tres")

# ---------------------------------------------------------------------------
# Exported properties
# ---------------------------------------------------------------------------

## Radius of each data-point when using the default sphere mesh (Godot units).
## Ignored when a custom [member point_mesh] or [member point_mesh_scene] is active.
@export_range(0.01, 1.0, 0.005) var point_radius: float = 0.08 :
	set(v):
		point_radius = v
		_queue_rebuild()

@export_group("Materials")

## Per-dataset point material overrides.  Index 0 → first dataset, index 1 → second, etc.
## An empty array (default) uses automatic per-dataset colors from [member Chart3D.colors].
## Assign any [Material] (including [ShaderMaterial]) at the matching index to override
## only that dataset; datasets without an entry keep their auto-color.
@export var point_materials: Array[Material] = [] :
	set(v):
		point_materials = v
		_queue_rebuild()

## Per-dataset albedo textures.  Applied as [code]albedo_texture[/code] on the
## auto-generated material when no [member point_materials] override is set for
## that dataset.  Ignored when a full material override is present.
@export var point_textures: Array[Texture2D] = [] :
	set(v):
		point_textures = v
		_queue_rebuild()

@export_group("Mesh Overrides")

## Single [Mesh] resource applied to all datasets (every point shares this mesh).
## Sub-classes may expose per-dataset arrays that take priority for individual datasets.
## null (default) = built-in unit sphere scaled by [member point_radius].
@export var point_mesh: Mesh = null :
	set(v):
		point_mesh = v
		_queue_rebuild()

## Single [PackedScene] applied to all datasets (every point shares this scene).
## Takes priority over [member point_mesh].
## Sub-classes may expose per-dataset arrays that take priority for individual datasets.
## null (default) = use [member point_mesh] or the built-in sphere.
@export var point_mesh_scene: PackedScene = null :
	set(v):
		point_mesh_scene = v
		_queue_rebuild()

@export_group("")

# ---------------------------------------------------------------------------
# Protected virtual methods — sub-classes override for per-dataset resolution
# ---------------------------------------------------------------------------

## Returns the [PackedScene] to use for dataset [param ds_idx].
## Default: returns [member point_mesh_scene] for every dataset.
## Override in sub-classes to supply per-dataset arrays (e.g. [ScatterChart3D]).
func _get_point_scene(ds_idx: int) -> PackedScene:
	return point_mesh_scene


## Returns the [Mesh] to use for dataset [param ds_idx].
## Default: returns [member point_mesh] for every dataset.
## Override in sub-classes to supply per-dataset arrays (e.g. [ScatterChart3D]).
func _get_point_mesh(ds_idx: int) -> Mesh:
	return point_mesh

# ---------------------------------------------------------------------------
# Protected helper
# ---------------------------------------------------------------------------

## Creates and returns a positioned point node for dataset [param ds_idx] at [param pos].
##
## Resolution order:
## [br]1. Per-dataset [PackedScene] ([method _get_point_scene])
## [br]2. Per-dataset [Mesh] ([method _get_point_mesh])
## [br]3. Built-in unit sphere scaled by [member point_radius]
##
## Material and texture are resolved from [member point_materials] and
## [member point_textures]; a full material override suppresses texture.
##
## [b]The returned node is NOT added to [member _container] — the caller must do that.[/b]
func _create_point_instance(ds_idx: int, pos: Vector3) -> Node3D:
	var color := _get_color(ds_idx)
	var mat_override: Material = point_materials[ds_idx] if ds_idx < point_materials.size() else null
	var tex: Texture2D = point_textures[ds_idx] if ds_idx < point_textures.size() else null

	# Scene takes highest priority.
	var ds_scene := _get_point_scene(ds_idx)
	if ds_scene != null:
		var inst := ds_scene.instantiate() as Node3D
		if inst != null:
			inst.position = pos
			if mat_override != null:
				_apply_material_to_scene(inst, mat_override)
			_apply_animation(inst)
		return inst

	# Mesh (user-provided or default sphere).
	var ds_mesh := _get_point_mesh(ds_idx)
	var mat: Material = _create_material_with_texture(color, tex, mat_override)
	var mi := MeshInstance3D.new()
	if ds_mesh != null:
		mi.mesh = ds_mesh
	else:
		mi.mesh = _DEFAULT_POINT_MESH
		mi.scale = Vector3.ONE * point_radius
	mi.material_override = mat
	mi.position = pos
	return mi
