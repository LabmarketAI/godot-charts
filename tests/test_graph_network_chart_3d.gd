extends GdUnitTestSuite

# Tests for GraphNetworkChart3D.
#
# Layout computation methods are pure calculation and do not need a scene tree.
# Instances are created without being added to the tree (no _ready()) so we
# can call layout helpers directly.

var _chart: GraphNetworkChart3D

const SAMPLE_NODES: Array = [
	{"id": "A", "label": "Alpha",   "type": "source", "x": 0.0, "y": 0.0, "z": 0.0},
	{"id": "B", "label": "Beta",    "type": "node",   "x": 1.0, "y": 0.5, "z": 0.5},
	{"id": "C", "label": "Gamma",   "type": "node",   "x": 0.5, "y": 1.0, "z": 0.2},
	{"id": "D", "label": "Delta",   "type": "sink",   "x": 0.2, "y": 0.5, "z": 1.0},
]
const SAMPLE_EDGES: Array = [
	{"source": "A", "target": "B", "directed": true},
	{"source": "B", "target": "C"},
	{"source": "C", "target": "D", "directed": true},
]


func before_test() -> void:
	_chart = auto_free(GraphNetworkChart3D.new())
	_chart.chart_size = Vector2(4.0, 3.0)
	_chart.node_radius = 0.15


# ---------------------------------------------------------------------------
# _layout_preset_3d
# ---------------------------------------------------------------------------

func test_preset_3d_returns_all_node_ids() -> void:
	var layout: Dictionary = _chart._layout_preset_3d(SAMPLE_NODES)
	assert_dict(layout).contains_keys(["A", "B", "C", "D"])


func test_preset_3d_positions_are_vector3() -> void:
	var layout: Dictionary = _chart._layout_preset_3d(SAMPLE_NODES)
	for id in layout:
		assert_object(layout[id]).is_instanceof(Vector3)


func test_preset_3d_z_values_are_distinct() -> void:
	# Nodes A and D differ in z (0.0 vs 1.0), so their mapped Z should differ.
	var layout: Dictionary = _chart._layout_preset_3d(SAMPLE_NODES)
	var za: float = (layout["A"] as Vector3).z
	var zd: float = (layout["D"] as Vector3).z
	assert_float(za).is_not_equal(zd)


func test_preset_3d_empty_nodes_returns_empty_dict() -> void:
	assert_dict(_chart._layout_preset_3d([])).is_empty()


# ---------------------------------------------------------------------------
# _layout_sphere (CIRCULAR)
# ---------------------------------------------------------------------------

func test_sphere_layout_returns_all_node_ids() -> void:
	var layout: Dictionary = _chart._layout_sphere(SAMPLE_NODES)
	assert_dict(layout).contains_keys(["A", "B", "C", "D"])


func test_sphere_layout_positions_are_vector3() -> void:
	var layout: Dictionary = _chart._layout_sphere(SAMPLE_NODES)
	for id in layout:
		assert_object(layout[id]).is_instanceof(Vector3)


func test_sphere_layout_single_node() -> void:
	var layout: Dictionary = _chart._layout_sphere([{"id": "solo"}])
	assert_dict(layout).contains_keys(["solo"])


func test_sphere_layout_empty_nodes_returns_empty() -> void:
	assert_dict(_chart._layout_sphere([])).is_empty()


# ---------------------------------------------------------------------------
# _layout_spring_3d_sync
# ---------------------------------------------------------------------------

func test_spring_3d_returns_all_node_ids() -> void:
	_chart.spring_iterations = 10
	var layout: Dictionary = _chart._layout_spring_3d_sync(SAMPLE_NODES, SAMPLE_EDGES)
	assert_dict(layout).contains_keys(["A", "B", "C", "D"])


func test_spring_3d_positions_are_vector3() -> void:
	_chart.spring_iterations = 10
	var layout: Dictionary = _chart._layout_spring_3d_sync(SAMPLE_NODES, SAMPLE_EDGES)
	for id in layout:
		assert_object(layout[id]).is_instanceof(Vector3)


func test_spring_3d_empty_nodes_returns_empty() -> void:
	var layout: Dictionary = _chart._layout_spring_3d_sync([], [])
	assert_dict(layout).is_empty()


# ---------------------------------------------------------------------------
# _normalize_to_chart_3d
# ---------------------------------------------------------------------------

func test_normalize_3d_empty_returns_empty() -> void:
	assert_dict(_chart._normalize_to_chart_3d({})).is_empty()


func test_normalize_3d_preserves_all_ids() -> void:
	var raw := {
		"X": Vector3(0.0, 0.0, 0.0),
		"Y": Vector3(1.0, 1.0, 1.0),
	}
	var result: Dictionary = _chart._normalize_to_chart_3d(raw)
	assert_dict(result).contains_keys(["X", "Y"])


func test_normalize_3d_x_order_preserved() -> void:
	var raw := {
		"left":  Vector3(0.0, 0.5, 0.5),
		"right": Vector3(1.0, 0.5, 0.5),
	}
	var result: Dictionary = _chart._normalize_to_chart_3d(raw)
	var xl: float = (result["left"] as Vector3).x
	var xr: float = (result["right"] as Vector3).x
	assert_float(xl).is_less(xr)


func test_normalize_3d_y_order_preserved() -> void:
	var raw := {
		"low":  Vector3(0.5, 0.0, 0.5),
		"high": Vector3(0.5, 1.0, 0.5),
	}
	var result: Dictionary = _chart._normalize_to_chart_3d(raw)
	var yl: float = (result["low"] as Vector3).y
	var yh: float = (result["high"] as Vector3).y
	assert_float(yl).is_less(yh)


# ---------------------------------------------------------------------------
# per-frame spring simulation state
# ---------------------------------------------------------------------------

func test_start_spring_sets_running_flag() -> void:
	_chart.spring_per_frame = true
	_chart.spring_iterations = 20
	_chart._start_spring_3d(SAMPLE_NODES, SAMPLE_EDGES)
	assert_bool(_chart._spring_running).is_true()


func test_start_spring_initialises_all_ids() -> void:
	_chart._start_spring_3d(SAMPLE_NODES, SAMPLE_EDGES)
	assert_array(_chart._spring_ids).has_size(SAMPLE_NODES.size())


func test_start_spring_returns_layout_with_all_nodes() -> void:
	var layout: Dictionary = _chart._start_spring_3d(SAMPLE_NODES, SAMPLE_EDGES)
	assert_dict(layout).contains_keys(["A", "B", "C", "D"])


# ---------------------------------------------------------------------------
# type → color index
# ---------------------------------------------------------------------------

func test_assign_type_indices_creates_entries() -> void:
	_chart._assign_type_indices(SAMPLE_NODES)
	assert_dict(_chart._type_color_index).contains_keys(["source", "node", "sink"])


func test_get_type_color_returns_color() -> void:
	var c := _chart._get_type_color("source")
	assert_object(c).is_instanceof(Color)


func test_same_type_same_color() -> void:
	var c1 := _chart._get_type_color("alpha_type")
	var c2 := _chart._get_type_color("alpha_type")
	assert_object(c1).is_equal(c2)


func test_two_types_different_color_indices() -> void:
	_chart._assign_type_indices(SAMPLE_NODES)
	var i_source: int = _chart._type_color_index["source"]
	var i_sink: int = _chart._type_color_index["sink"]
	assert_bool(i_source != i_sink).is_true()


# ---------------------------------------------------------------------------
# data source integration
# ---------------------------------------------------------------------------

func test_data_source_accepted() -> void:
	var src := auto_free(GraphNetworkDataSource.new())
	src.load_from_dict({"nodes": [{"id": "A"}], "edges": []})
	_chart.data_source = src
	assert_object(_chart.data_source).is_not_null()


func test_data_source_get_source_data_matches_loaded() -> void:
	var src := auto_free(GraphNetworkDataSource.new())
	src.load_from_dict({
		"nodes": SAMPLE_NODES,
		"edges": SAMPLE_EDGES,
	})
	_chart.data_source = src
	var d: Dictionary = _chart._get_source_data()
	assert_array(d["nodes"]).has_size(SAMPLE_NODES.size())
	assert_array(d["edges"]).has_size(SAMPLE_EDGES.size())


# ---------------------------------------------------------------------------
# GraphNetworkChartBase properties accessible from GraphNetworkChart3D
# ---------------------------------------------------------------------------

func test_base_node_default_mesh_accessible() -> void:
	var m := SphereMesh.new()
	_chart.node_default_mesh = m
	assert_object(_chart.node_default_mesh).is_equal(m)


func test_base_node_type_meshes_accessible() -> void:
	var m := BoxMesh.new()
	_chart.node_type_meshes = {"source": m}
	assert_object(_chart.node_type_meshes["source"]).is_equal(m)


func test_base_node_default_texture_accessible() -> void:
	var tex := ImageTexture.new()
	_chart.node_default_texture = tex
	assert_object(_chart.node_default_texture).is_equal(tex)


func test_base_edge_radius_accessible() -> void:
	_chart.edge_radius = 0.03
	assert_float(_chart.edge_radius).is_equal_approx(0.03, 0.0001)


func test_base_edge_default_texture_accessible() -> void:
	var tex := ImageTexture.new()
	_chart.edge_default_texture = tex
	assert_object(_chart.edge_default_texture).is_equal(tex)


func test_base_get_node_mesh_falls_through_to_preloaded_default() -> void:
	# No overrides → returns the preloaded _DEFAULT_NODE_MESH (non-null).
	var m := _chart._get_node_mesh("node")
	assert_object(m).is_not_null()


func test_base_spring_per_frame_queues_rebuild() -> void:
	_chart._rebuild_queued = false
	_chart.spring_per_frame = true
	assert_bool(_chart._rebuild_queued).is_true()
