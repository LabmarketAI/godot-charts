extends GdUnitTestSuite

# Tests for GraphNetworkChartBase shared logic.
#
# GraphNetworkChartBase is abstract; we use GraphNetworkChart2D as the concrete
# driver since it is the simplest subclass and all tested methods live on the
# base class.  No scene tree is required for pure-calculation helpers.

var _chart: GraphNetworkChart2D

const SAMPLE_NODES: Array = [
	{"id": "A", "label": "Alice", "type": "person"},
	{"id": "B", "label": "Bob",   "type": "person"},
	{"id": "C", "label": "Corp",  "type": "org"},
]
const SAMPLE_EDGES: Array = [
	{"source": "A", "target": "B"},
	{"source": "B", "target": "C", "type": "employs"},
]


func before_test() -> void:
	_chart = auto_free(GraphNetworkChart2D.new())
	_chart.chart_size = Vector2(4.0, 3.0)
	_chart.node_radius = 0.15


# ---------------------------------------------------------------------------
# _get_node_mesh — resolution priority
# ---------------------------------------------------------------------------

func test_get_node_mesh_returns_default_when_no_overrides() -> void:
	# No overrides → fallback to preloaded _DEFAULT_NODE_MESH (non-null).
	var m := _chart._get_node_mesh("person")
	assert_object(m).is_not_null()


func test_get_node_mesh_returns_default_mesh_override() -> void:
	var m := SphereMesh.new()
	_chart.node_default_mesh = m
	assert_object(_chart._get_node_mesh("person")).is_equal(m)
	assert_object(_chart._get_node_mesh("org")).is_equal(m)


func test_get_node_mesh_type_specific_overrides_default() -> void:
	var default_m := SphereMesh.new()
	var type_m := BoxMesh.new()
	_chart.node_default_mesh = default_m
	_chart.node_type_meshes = {"person": type_m}
	assert_object(_chart._get_node_mesh("person")).is_equal(type_m)
	assert_object(_chart._get_node_mesh("org")).is_equal(default_m)


func test_get_node_mesh_ignores_non_mesh_type_entry() -> void:
	_chart.node_type_meshes = {"person": "not_a_mesh"}
	# Non-Mesh value should be ignored; falls through to preloaded default.
	var m := _chart._get_node_mesh("person")
	assert_object(m).is_not_null()


# ---------------------------------------------------------------------------
# _get_node_texture — resolution priority
# ---------------------------------------------------------------------------

func test_get_node_texture_returns_null_when_no_overrides() -> void:
	assert_object(_chart._get_node_texture("person")).is_null()


func test_get_node_texture_returns_default_texture() -> void:
	var tex := ImageTexture.new()
	_chart.node_default_texture = tex
	assert_object(_chart._get_node_texture("person")).is_equal(tex)
	assert_object(_chart._get_node_texture("org")).is_equal(tex)


func test_get_node_texture_type_specific_overrides_default() -> void:
	var default_tex := ImageTexture.new()
	var type_tex := ImageTexture.new()
	_chart.node_default_texture = default_tex
	_chart.node_type_textures = {"person": type_tex}
	assert_object(_chart._get_node_texture("person")).is_equal(type_tex)
	assert_object(_chart._get_node_texture("org")).is_equal(default_tex)


func test_get_node_texture_unknown_type_falls_back_to_default() -> void:
	var tex := ImageTexture.new()
	_chart.node_default_texture = tex
	assert_object(_chart._get_node_texture("unknown_type")).is_equal(tex)


# ---------------------------------------------------------------------------
# _get_edge_texture — resolution priority
# ---------------------------------------------------------------------------

func test_get_edge_texture_returns_null_when_no_overrides() -> void:
	assert_object(_chart._get_edge_texture("employs")).is_null()


func test_get_edge_texture_returns_default_texture() -> void:
	var tex := ImageTexture.new()
	_chart.edge_default_texture = tex
	assert_object(_chart._get_edge_texture("employs")).is_equal(tex)
	assert_object(_chart._get_edge_texture("")).is_equal(tex)


func test_get_edge_texture_type_specific_overrides_default() -> void:
	var default_tex := ImageTexture.new()
	var type_tex := ImageTexture.new()
	_chart.edge_default_texture = default_tex
	_chart.edge_type_textures = {"employs": type_tex}
	assert_object(_chart._get_edge_texture("employs")).is_equal(type_tex)
	assert_object(_chart._get_edge_texture("")).is_equal(default_tex)


# ---------------------------------------------------------------------------
# _layout_position_to_vector3 — conversion helper
# ---------------------------------------------------------------------------

func test_layout_position_vector2_becomes_vector3_z0() -> void:
	var v3 := _chart._layout_position_to_vector3(Vector2(1.0, 2.0))
	assert_object(v3).is_instanceof(Vector3)
	assert_float(v3.x).is_equal_approx(1.0, 0.001)
	assert_float(v3.y).is_equal_approx(2.0, 0.001)
	assert_float(v3.z).is_equal_approx(0.0, 0.001)


func test_layout_position_vector3_passes_through() -> void:
	var src := Vector3(1.0, 2.0, 3.0)
	var v3 := _chart._layout_position_to_vector3(src)
	assert_object(v3).is_equal(src)


func test_layout_position_null_returns_zero() -> void:
	var v3 := _chart._layout_position_to_vector3(null)
	assert_object(v3).is_equal(Vector3.ZERO)


# ---------------------------------------------------------------------------
# _assign_type_indices / _get_type_color
# ---------------------------------------------------------------------------

func test_assign_type_indices_adds_all_unique_types() -> void:
	_chart._assign_type_indices(SAMPLE_NODES)
	assert_dict(_chart._type_color_index).contains_keys(["person", "org"])


func test_assign_type_indices_stable_across_multiple_calls() -> void:
	_chart._assign_type_indices(SAMPLE_NODES)
	var idx_person_first: int = _chart._type_color_index["person"]
	_chart._assign_type_indices(SAMPLE_NODES)
	assert_int(_chart._type_color_index["person"]).is_equal(idx_person_first)


func test_get_type_color_returns_a_color() -> void:
	var c := _chart._get_type_color("person")
	assert_object(c).is_instanceof(Color)


func test_same_type_always_same_color() -> void:
	var c1 := _chart._get_type_color("person")
	var c2 := _chart._get_type_color("person")
	assert_object(c1).is_equal(c2)


func test_different_types_different_color_indices() -> void:
	_chart._assign_type_indices(SAMPLE_NODES)
	var ip: int = _chart._type_color_index["person"]
	var io: int = _chart._type_color_index["org"]
	assert_bool(ip != io).is_true()


# ---------------------------------------------------------------------------
# _create_node_instance — returns a valid Node3D
# ---------------------------------------------------------------------------

func test_create_node_instance_returns_mesh_instance_by_default() -> void:
	_chart._assign_type_indices(SAMPLE_NODES)
	var inst := _chart._create_node_instance(SAMPLE_NODES[0], Vector3.ZERO)
	auto_free(inst)
	assert_object(inst).is_instanceof(MeshInstance3D)


func test_create_node_instance_position_set() -> void:
	_chart._assign_type_indices(SAMPLE_NODES)
	var pos := Vector3(1.0, 2.0, 0.0)
	var inst := _chart._create_node_instance(SAMPLE_NODES[0], pos)
	auto_free(inst)
	assert_object(inst.position).is_equal(pos)


func test_create_node_instance_applies_node_default_texture() -> void:
	_chart._assign_type_indices(SAMPLE_NODES)
	var tex := ImageTexture.new()
	_chart.node_default_texture = tex
	var inst := _chart._create_node_instance(SAMPLE_NODES[0], Vector3.ZERO)
	auto_free(inst)
	var mi := inst as MeshInstance3D
	assert_object(mi).is_not_null()
	var mat := mi.material_override as StandardMaterial3D
	assert_object(mat.albedo_texture).is_equal(tex)


func test_create_node_instance_uses_type_mesh_override() -> void:
	_chart._assign_type_indices(SAMPLE_NODES)
	var m := BoxMesh.new()
	_chart.node_type_meshes = {"person": m}
	var inst := _chart._create_node_instance(SAMPLE_NODES[0], Vector3.ZERO)
	auto_free(inst)
	var mi := inst as MeshInstance3D
	assert_object(mi.mesh).is_equal(m)


# ---------------------------------------------------------------------------
# Public API — pop_node / collapse_node / pop_all / collapse_all
# (These do not need a scene tree — they operate on _node_instances dict)
# ---------------------------------------------------------------------------

func test_pop_node_does_not_crash_when_id_not_found() -> void:
	# Should be a no-op; must not crash.
	_chart.pop_node("nonexistent")
	assert_bool(true).is_true()


func test_collapse_node_does_not_crash_when_id_not_found() -> void:
	_chart.collapse_node("nonexistent")
	assert_bool(true).is_true()


func test_pop_all_and_collapse_all_no_crash_with_empty_instances() -> void:
	_chart.pop_all()
	_chart.collapse_all()
	assert_bool(true).is_true()


# ---------------------------------------------------------------------------
# Setter consistency — key Phase 3 properties queue a rebuild
# ---------------------------------------------------------------------------

func test_setting_node_default_mesh_queues_rebuild() -> void:
	_chart._rebuild_queued = false
	_chart.node_default_mesh = SphereMesh.new()
	assert_bool(_chart._rebuild_queued).is_true()


func test_setting_node_type_meshes_queues_rebuild() -> void:
	_chart._rebuild_queued = false
	_chart.node_type_meshes = {"person": BoxMesh.new()}
	assert_bool(_chart._rebuild_queued).is_true()


func test_setting_node_default_texture_queues_rebuild() -> void:
	_chart._rebuild_queued = false
	_chart.node_default_texture = ImageTexture.new()
	assert_bool(_chart._rebuild_queued).is_true()


func test_setting_node_type_textures_queues_rebuild() -> void:
	_chart._rebuild_queued = false
	_chart.node_type_textures = {"person": ImageTexture.new()}
	assert_bool(_chart._rebuild_queued).is_true()


func test_setting_edge_default_texture_queues_rebuild() -> void:
	_chart._rebuild_queued = false
	_chart.edge_default_texture = ImageTexture.new()
	assert_bool(_chart._rebuild_queued).is_true()


func test_setting_edge_type_textures_queues_rebuild() -> void:
	_chart._rebuild_queued = false
	_chart.edge_type_textures = {"employs": ImageTexture.new()}
	assert_bool(_chart._rebuild_queued).is_true()


func test_setting_edge_radius_queues_rebuild() -> void:
	_chart._rebuild_queued = false
	_chart.edge_radius = 0.05
	assert_bool(_chart._rebuild_queued).is_true()


func test_setting_edge_mesh_scene_queues_rebuild() -> void:
	_chart._rebuild_queued = false
	_chart.edge_mesh_scene = null
	assert_bool(_chart._rebuild_queued).is_true()


func test_setting_node_type_scenes_queues_rebuild() -> void:
	_chart._rebuild_queued = false
	_chart.node_type_scenes = {}
	assert_bool(_chart._rebuild_queued).is_true()


func test_setting_node_type_materials_queues_rebuild() -> void:
	_chart._rebuild_queued = false
	_chart.node_type_materials = {}
	assert_bool(_chart._rebuild_queued).is_true()


func test_setting_layout_mode_queues_rebuild() -> void:
	_chart._rebuild_queued = false
	_chart.layout_mode = GraphNetworkChartBase.LayoutMode.CIRCULAR
	assert_bool(_chart._rebuild_queued).is_true()


func test_setting_node_radius_queues_rebuild() -> void:
	_chart._rebuild_queued = false
	_chart.node_radius = 0.25
	assert_bool(_chart._rebuild_queued).is_true()


func test_setting_edge_width_queues_rebuild() -> void:
	_chart._rebuild_queued = false
	_chart.edge_width = 0.05
	assert_bool(_chart._rebuild_queued).is_true()


func test_setting_show_node_labels_queues_rebuild() -> void:
	_chart._rebuild_queued = false
	_chart.show_node_labels = false
	assert_bool(_chart._rebuild_queued).is_true()


func test_setting_show_edge_labels_queues_rebuild() -> void:
	_chart._rebuild_queued = false
	_chart.show_edge_labels = true
	assert_bool(_chart._rebuild_queued).is_true()


func test_setting_edge_weight_scale_queues_rebuild() -> void:
	_chart._rebuild_queued = false
	_chart.edge_weight_scale = 0.5
	assert_bool(_chart._rebuild_queued).is_true()
