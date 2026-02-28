extends GdUnitTestSuite

# Tests for GraphNetworkChart2D.
#
# Layout computation methods are pure calculation and do not need a scene tree.
# We create chart instances without adding them (no _ready()) to test layout
# internals directly, then add a minimal scene-tree instance for render tests.

var _chart: GraphNetworkChart2D

# Sample graph data used across tests.
const SAMPLE_NODES: Array = [
	{"id": "A", "label": "Alice", "type": "person", "x": 0.0, "y": 1.0},
	{"id": "B", "label": "Bob",   "type": "person", "x": 1.0, "y": 0.0},
	{"id": "C", "label": "Corp",  "type": "org",    "x": 0.5, "y": 0.5},
]
const SAMPLE_EDGES: Array = [
	{"source": "A", "target": "B"},
	{"source": "B", "target": "C"},
]


func before_test() -> void:
	_chart = auto_free(GraphNetworkChart2D.new())
	# Set a fixed chart size so layout assertions are deterministic.
	_chart.chart_size = Vector2(4.0, 3.0)
	_chart.node_radius = 0.15


# ---------------------------------------------------------------------------
# _layout_preset
# ---------------------------------------------------------------------------

func test_preset_layout_returns_all_node_ids() -> void:
	var layout: Dictionary = _chart._layout_preset(SAMPLE_NODES)
	assert_dict(layout).contains_keys(["A", "B", "C"])


func test_preset_layout_positions_are_vector2() -> void:
	var layout: Dictionary = _chart._layout_preset(SAMPLE_NODES)
	for id in layout:
		assert_object(layout[id]).is_instanceof(Vector2)


func test_preset_layout_fits_within_chart_size() -> void:
	var layout: Dictionary = _chart._layout_preset(SAMPLE_NODES)
	for id in layout:
		var p: Vector2 = layout[id]
		assert_float(p.x).is_greater_equal(0.0)
		assert_float(p.x).is_less_equal(_chart.chart_size.x)
		assert_float(p.y).is_greater_equal(0.0)
		assert_float(p.y).is_less_equal(_chart.chart_size.y)


func test_preset_layout_empty_nodes_returns_empty_dict() -> void:
	var layout: Dictionary = _chart._layout_preset([])
	assert_dict(layout).is_empty()


# ---------------------------------------------------------------------------
# _layout_circular
# ---------------------------------------------------------------------------

func test_circular_layout_returns_all_node_ids() -> void:
	var layout: Dictionary = _chart._layout_circular(SAMPLE_NODES)
	assert_dict(layout).contains_keys(["A", "B", "C"])


func test_circular_layout_positions_are_vector2() -> void:
	var layout: Dictionary = _chart._layout_circular(SAMPLE_NODES)
	for id in layout:
		assert_object(layout[id]).is_instanceof(Vector2)


func test_circular_layout_fits_within_chart_size() -> void:
	var layout: Dictionary = _chart._layout_circular(SAMPLE_NODES)
	for id in layout:
		var p: Vector2 = layout[id]
		assert_float(p.x).is_greater_equal(0.0)
		assert_float(p.x).is_less_equal(_chart.chart_size.x)
		assert_float(p.y).is_greater_equal(0.0)
		assert_float(p.y).is_less_equal(_chart.chart_size.y)


func test_circular_layout_single_node() -> void:
	var layout: Dictionary = _chart._layout_circular([{"id": "solo"}])
	assert_dict(layout).contains_keys(["solo"])


func test_circular_layout_empty_nodes_returns_empty_dict() -> void:
	assert_dict(_chart._layout_circular([])).is_empty()


# ---------------------------------------------------------------------------
# _layout_spring
# ---------------------------------------------------------------------------

func test_spring_layout_returns_all_node_ids() -> void:
	_chart.spring_iterations = 10
	var layout: Dictionary = _chart._layout_spring(SAMPLE_NODES, SAMPLE_EDGES)
	assert_dict(layout).contains_keys(["A", "B", "C"])


func test_spring_layout_positions_are_vector2() -> void:
	_chart.spring_iterations = 10
	var layout: Dictionary = _chart._layout_spring(SAMPLE_NODES, SAMPLE_EDGES)
	for id in layout:
		assert_object(layout[id]).is_instanceof(Vector2)


func test_spring_layout_fits_within_chart_size() -> void:
	_chart.spring_iterations = 10
	var layout: Dictionary = _chart._layout_spring(SAMPLE_NODES, SAMPLE_EDGES)
	for id in layout:
		var p: Vector2 = layout[id]
		assert_float(p.x).is_greater_equal(0.0)
		assert_float(p.x).is_less_equal(_chart.chart_size.x)
		assert_float(p.y).is_greater_equal(0.0)
		assert_float(p.y).is_less_equal(_chart.chart_size.y)


func test_spring_layout_empty_nodes_returns_empty_dict() -> void:
	var layout: Dictionary = _chart._layout_spring([], [])
	assert_dict(layout).is_empty()


# ---------------------------------------------------------------------------
# _normalize_to_chart
# ---------------------------------------------------------------------------

func test_normalize_single_node_gets_centre_position() -> void:
	var raw := {"X": Vector2(5.0, 7.0)}
	var result: Dictionary = _chart._normalize_to_chart(raw)
	# With a single point, range = 1 and the point lands at margin.
	assert_dict(result).contains_keys(["X"])


func test_normalize_empty_dict_returns_empty() -> void:
	assert_dict(_chart._normalize_to_chart({})).is_empty()


func test_normalize_preserves_relative_order() -> void:
	# Node "left" has smaller x than "right" in raw space; must remain so after normalisation.
	var raw := {
		"left":  Vector2(0.0, 0.5),
		"right": Vector2(1.0, 0.5),
	}
	var result: Dictionary = _chart._normalize_to_chart(raw)
	var px_left: float = (result["left"] as Vector2).x
	var px_right: float = (result["right"] as Vector2).x
	assert_float(px_left).is_less(px_right)


# ---------------------------------------------------------------------------
# type → color index
# ---------------------------------------------------------------------------

func test_assign_type_indices_maps_unique_types() -> void:
	_chart._assign_type_indices(SAMPLE_NODES)
	assert_dict(_chart._type_color_index).contains_keys(["person", "org"])


func test_get_type_color_returns_color() -> void:
	var c := _chart._get_type_color("person")
	assert_object(c).is_instanceof(Color)


func test_same_type_gets_same_color() -> void:
	var c1 := _chart._get_type_color("foo")
	var c2 := _chart._get_type_color("foo")
	assert_object(c1).is_equal(c2)


func test_different_types_get_different_color_indices() -> void:
	_chart._assign_type_indices(SAMPLE_NODES)
	var idx_person: int = _chart._type_color_index["person"]
	var idx_org: int = _chart._type_color_index["org"]
	assert_bool(idx_person != idx_org).is_true()


# ---------------------------------------------------------------------------
# data source integration
# ---------------------------------------------------------------------------

func test_data_source_assignment_accepted() -> void:
	var src := auto_free(GraphNetworkDataSource.new())
	src.load_from_dict({"nodes": [{"id": "A"}], "edges": []})
	_chart.data_source = src
	assert_object(_chart.data_source).is_not_null()


func test_data_source_get_data_node_count() -> void:
	var src := auto_free(GraphNetworkDataSource.new())
	src.load_from_dict({
		"nodes": [{"id": "A"}, {"id": "B"}],
		"edges": [],
	})
	_chart.data_source = src
	var d: Dictionary = _chart._get_source_data()
	assert_array(d["nodes"]).has_size(2)


# ---------------------------------------------------------------------------
# GraphNetworkChartBase properties accessible from GraphNetworkChart2D
# ---------------------------------------------------------------------------

func test_base_node_default_mesh_accessible() -> void:
	var m := SphereMesh.new()
	_chart.node_default_mesh = m
	assert_object(_chart.node_default_mesh).is_equal(m)


func test_base_node_type_meshes_accessible() -> void:
	var m := BoxMesh.new()
	_chart.node_type_meshes = {"person": m}
	assert_object(_chart.node_type_meshes["person"]).is_equal(m)


func test_base_node_default_texture_accessible() -> void:
	var tex := ImageTexture.new()
	_chart.node_default_texture = tex
	assert_object(_chart.node_default_texture).is_equal(tex)


func test_base_node_type_textures_accessible() -> void:
	var tex := ImageTexture.new()
	_chart.node_type_textures = {"org": tex}
	assert_object(_chart.node_type_textures["org"]).is_equal(tex)


func test_base_edge_radius_accessible() -> void:
	_chart.edge_radius = 0.05
	assert_float(_chart.edge_radius).is_equal_approx(0.05, 0.0001)


func test_base_edge_default_texture_accessible() -> void:
	var tex := ImageTexture.new()
	_chart.edge_default_texture = tex
	assert_object(_chart.edge_default_texture).is_equal(tex)


func test_base_edge_type_textures_accessible() -> void:
	var tex := ImageTexture.new()
	_chart.edge_type_textures = {"employs": tex}
	assert_object(_chart.edge_type_textures["employs"]).is_equal(tex)


func test_base_get_node_mesh_resolution_order() -> void:
	# type-specific mesh overrides default mesh.
	var default_m := SphereMesh.new()
	var type_m := BoxMesh.new()
	_chart.node_default_mesh = default_m
	_chart.node_type_meshes = {"person": type_m}
	assert_object(_chart._get_node_mesh("person")).is_equal(type_m)
	assert_object(_chart._get_node_mesh("org")).is_equal(default_m)


func test_base_get_edge_texture_resolution_order() -> void:
	var default_tex := ImageTexture.new()
	var type_tex := ImageTexture.new()
	_chart.edge_default_texture = default_tex
	_chart.edge_type_textures = {"employs": type_tex}
	assert_object(_chart._get_edge_texture("employs")).is_equal(type_tex)
	assert_object(_chart._get_edge_texture("")).is_equal(default_tex)
