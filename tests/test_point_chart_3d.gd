extends GdUnitTestSuite

# Tests for PointChart3D shared point-instance creation logic.
#
# PointChart3D is abstract; we use ScatterChart3D as the concrete driver since
# it extends PointChart3D without adding conflicting point-resolution logic.
# All tested methods live on PointChart3D and are accessible via the subclass.

var _chart: ScatterChart3D


func before_test() -> void:
	_chart = auto_free(ScatterChart3D.new())
	_chart.chart_size = Vector2(4.0, 3.0)


# ---------------------------------------------------------------------------
# _get_point_mesh — resolution priority
# ---------------------------------------------------------------------------

func test_get_point_mesh_returns_null_when_no_override() -> void:
	# PointChart3D.point_mesh is null by default; _get_point_mesh should return null.
	assert_object(_chart._get_point_mesh(0)).is_null()


func test_get_point_mesh_returns_single_override() -> void:
	var m := SphereMesh.new()
	_chart.point_mesh = m
	assert_object(_chart._get_point_mesh(0)).is_equal(m)
	assert_object(_chart._get_point_mesh(1)).is_equal(m)


func test_scatter_per_dataset_mesh_overrides_single_override() -> void:
	var single := SphereMesh.new()
	var per_ds := BoxMesh.new()
	_chart.point_mesh = single
	_chart.point_meshes = [per_ds]
	# Dataset 0 → per-dataset array; dataset 1 → single override.
	assert_object(_chart._get_point_mesh(0)).is_equal(per_ds)
	assert_object(_chart._get_point_mesh(1)).is_equal(single)


# ---------------------------------------------------------------------------
# _get_point_scene — resolution priority
# ---------------------------------------------------------------------------

func test_get_point_scene_returns_null_when_no_override() -> void:
	assert_object(_chart._get_point_scene(0)).is_null()


func test_scatter_per_dataset_scene_returned_for_correct_index() -> void:
	var scn := PackedScene.new()
	_chart.point_mesh_scenes = [scn]
	assert_object(_chart._get_point_scene(0)).is_equal(scn)
	assert_object(_chart._get_point_scene(1)).is_null()


# ---------------------------------------------------------------------------
# _create_point_instance — mesh path
# ---------------------------------------------------------------------------

func test_create_point_instance_returns_node3d() -> void:
	var inst := _chart._create_point_instance(0, Vector3.ZERO)
	auto_free(inst)
	assert_object(inst).is_not_null()
	assert_object(inst).is_instanceof(Node3D)


func test_create_point_instance_position_is_set() -> void:
	var pos := Vector3(1.0, 2.0, 3.0)
	var inst := _chart._create_point_instance(0, pos)
	auto_free(inst)
	assert_object(inst.position).is_equal(pos)


func test_create_point_instance_uses_default_sphere_when_no_override() -> void:
	# With no overrides the fallback is the preloaded default sphere MeshInstance3D.
	var inst := _chart._create_point_instance(0, Vector3.ZERO)
	auto_free(inst)
	assert_object(inst).is_instanceof(MeshInstance3D)
	var mi := inst as MeshInstance3D
	assert_object(mi.mesh).is_not_null()


func test_create_point_instance_uses_custom_mesh() -> void:
	var m := BoxMesh.new()
	_chart.point_mesh = m
	var inst := _chart._create_point_instance(0, Vector3.ZERO)
	auto_free(inst)
	assert_object(inst).is_instanceof(MeshInstance3D)
	assert_object((inst as MeshInstance3D).mesh).is_equal(m)


func test_create_point_instance_scale_matches_point_radius() -> void:
	_chart.point_radius = 0.2
	var inst := _chart._create_point_instance(0, Vector3.ZERO)
	auto_free(inst)
	# Default sphere path: scale = Vector3.ONE * point_radius.
	assert_float(inst.scale.x).is_equal_approx(0.2, 0.001)
	assert_float(inst.scale.y).is_equal_approx(0.2, 0.001)
	assert_float(inst.scale.z).is_equal_approx(0.2, 0.001)


# ---------------------------------------------------------------------------
# _create_point_instance — material / texture path
# ---------------------------------------------------------------------------

func test_create_point_instance_applies_material_override() -> void:
	var mat := StandardMaterial3D.new()
	_chart.point_materials = [mat]
	var inst := _chart._create_point_instance(0, Vector3.ZERO)
	auto_free(inst)
	assert_object((inst as MeshInstance3D).material_override).is_equal(mat)


func test_create_point_instance_no_material_override_when_index_out_of_range() -> void:
	# point_materials has 0 entries; dataset 0 should get an auto-generated material.
	var inst := _chart._create_point_instance(0, Vector3.ZERO)
	auto_free(inst)
	var mi := inst as MeshInstance3D
	# Auto-generated StandardMaterial3D should be present (not null).
	assert_object(mi.material_override).is_not_null()


func test_create_point_instance_texture_applied_when_no_material_override() -> void:
	var tex := ImageTexture.new()
	_chart.point_textures = [tex]
	var inst := _chart._create_point_instance(0, Vector3.ZERO)
	auto_free(inst)
	var mi := inst as MeshInstance3D
	var mat := mi.material_override as StandardMaterial3D
	assert_object(mat).is_not_null()
	assert_object(mat.albedo_texture).is_equal(tex)


func test_create_point_instance_texture_ignored_when_material_override_present() -> void:
	# A full material override should be returned unchanged; texture is not applied.
	var mat := StandardMaterial3D.new()
	_chart.point_materials = [mat]
	var tex := ImageTexture.new()
	_chart.point_textures = [tex]
	var inst := _chart._create_point_instance(0, Vector3.ZERO)
	auto_free(inst)
	# The override material should have no albedo_texture set by the chart.
	assert_object((inst as MeshInstance3D).material_override).is_equal(mat)


# ---------------------------------------------------------------------------
# Setter consistency — property changes queue a rebuild
# ---------------------------------------------------------------------------

func test_setting_point_radius_queues_rebuild() -> void:
	_chart._rebuild_queued = false
	_chart.point_radius = 0.15
	assert_bool(_chart._rebuild_queued).is_true()


func test_setting_point_mesh_queues_rebuild() -> void:
	_chart._rebuild_queued = false
	_chart.point_mesh = SphereMesh.new()
	assert_bool(_chart._rebuild_queued).is_true()


func test_setting_point_materials_queues_rebuild() -> void:
	_chart._rebuild_queued = false
	_chart.point_materials = [StandardMaterial3D.new()]
	assert_bool(_chart._rebuild_queued).is_true()


func test_setting_point_textures_queues_rebuild() -> void:
	_chart._rebuild_queued = false
	_chart.point_textures = [ImageTexture.new()]
	assert_bool(_chart._rebuild_queued).is_true()


func test_setting_point_mesh_scene_queues_rebuild() -> void:
	_chart._rebuild_queued = false
	_chart.point_mesh_scene = null  # assigning null still triggers setter
	assert_bool(_chart._rebuild_queued).is_true()


func test_setting_scatter_point_meshes_queues_rebuild() -> void:
	_chart._rebuild_queued = false
	_chart.point_meshes = [BoxMesh.new()]
	assert_bool(_chart._rebuild_queued).is_true()
