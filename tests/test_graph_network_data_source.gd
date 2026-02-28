extends GdUnitTestSuite

# Tests for GraphNetworkDataSource.
# No scene tree required — resource instances work without _ready().

var _source: GraphNetworkDataSource


func before_test() -> void:
	_source = auto_free(GraphNetworkDataSource.new())


# ---------------------------------------------------------------------------
# get_data defaults
# ---------------------------------------------------------------------------

func test_get_data_default_has_nodes_and_edges_keys() -> void:
	var d := _source.get_data()
	assert_dict(d).contains_keys(["nodes", "edges"])


func test_get_data_default_nodes_empty() -> void:
	assert_array(_source.get_data()["nodes"]).is_empty()


func test_get_data_default_edges_empty() -> void:
	assert_array(_source.get_data()["edges"]).is_empty()


# ---------------------------------------------------------------------------
# load_from_dict
# ---------------------------------------------------------------------------

func test_load_from_dict_populates_nodes() -> void:
	_source.load_from_dict({
		"nodes": [{"id": "A"}, {"id": "B"}],
		"edges": [],
	})
	assert_array(_source.get_data()["nodes"]).has_size(2)


func test_load_from_dict_populates_edges() -> void:
	_source.load_from_dict({
		"nodes": [{"id": "A"}, {"id": "B"}],
		"edges": [{"source": "A", "target": "B"}],
	})
	assert_array(_source.get_data()["edges"]).has_size(1)


func test_load_from_dict_emits_data_updated() -> void:
	var emitted := false
	_source.data_updated.connect(func(_d: Dictionary) -> void: emitted = true)
	_source.load_from_dict({"nodes": [], "edges": []})
	assert_bool(emitted).is_true()


func test_load_from_dict_signal_carries_correct_node_count() -> void:
	var received: Dictionary = {}
	_source.data_updated.connect(func(d: Dictionary) -> void: received = d)
	_source.load_from_dict({
		"nodes": [{"id": "X"}, {"id": "Y"}, {"id": "Z"}],
		"edges": [],
	})
	assert_array(received["nodes"]).has_size(3)


func test_load_from_dict_overwrites_previous_data() -> void:
	_source.load_from_dict({"nodes": [{"id": "A"}], "edges": []})
	_source.load_from_dict({"nodes": [], "edges": []})
	assert_array(_source.get_data()["nodes"]).is_empty()


# ---------------------------------------------------------------------------
# add_node
# ---------------------------------------------------------------------------

func test_add_node_increases_node_count() -> void:
	_source.add_node("A", {"label": "Alice"})
	assert_array(_source.get_data()["nodes"]).has_size(1)


func test_add_node_preserves_id() -> void:
	_source.add_node("mynode", {"label": "Test"})
	var nodes: Array = _source.get_data()["nodes"]
	assert_str(str(nodes[0]["id"])).is_equal("mynode")


func test_add_node_emits_data_updated() -> void:
	var emitted := false
	_source.data_updated.connect(func(_d: Dictionary) -> void: emitted = true)
	_source.add_node("A")
	assert_bool(emitted).is_true()


func test_add_node_replaces_existing_node_with_same_id() -> void:
	_source.add_node("A", {"label": "Old"})
	_source.add_node("A", {"label": "New"})
	var nodes: Array = _source.get_data()["nodes"]
	assert_array(nodes).has_size(1)
	assert_str(str(nodes[0]["label"])).is_equal("New")


# ---------------------------------------------------------------------------
# remove_node
# ---------------------------------------------------------------------------

func test_remove_node_decreases_node_count() -> void:
	_source.add_node("A")
	_source.add_node("B")
	_source.remove_node("A")
	assert_array(_source.get_data()["nodes"]).has_size(1)


func test_remove_node_emits_data_updated() -> void:
	_source.add_node("A")
	var emitted := false
	_source.data_updated.connect(func(_d: Dictionary) -> void: emitted = true)
	_source.remove_node("A")
	assert_bool(emitted).is_true()


func test_remove_node_also_removes_incident_edges() -> void:
	_source.add_node("A")
	_source.add_node("B")
	_source.add_node("C")
	_source.add_edge("A", "B")
	_source.add_edge("B", "C")
	_source.remove_node("B")
	assert_array(_source.get_data()["edges"]).is_empty()


func test_remove_nonexistent_node_is_silent() -> void:
	_source.remove_node("ghost")  # must not throw
	assert_array(_source.get_data()["nodes"]).is_empty()


# ---------------------------------------------------------------------------
# add_edge / remove_edge
# ---------------------------------------------------------------------------

func test_add_edge_increases_edge_count() -> void:
	_source.add_node("A")
	_source.add_node("B")
	_source.add_edge("A", "B")
	assert_array(_source.get_data()["edges"]).has_size(1)


func test_add_edge_emits_data_updated() -> void:
	var emitted := false
	_source.data_updated.connect(func(_d: Dictionary) -> void: emitted = true)
	_source.add_edge("A", "B")
	assert_bool(emitted).is_true()


func test_add_edge_stores_source_and_target() -> void:
	_source.add_edge("X", "Y", {"weight": 2.5})
	var edges: Array = _source.get_data()["edges"]
	assert_str(str(edges[0]["source"])).is_equal("X")
	assert_str(str(edges[0]["target"])).is_equal("Y")


func test_remove_edge_decreases_edge_count() -> void:
	_source.add_edge("A", "B")
	_source.add_edge("B", "C")
	_source.remove_edge("A", "B")
	assert_array(_source.get_data()["edges"]).has_size(1)


func test_remove_edge_emits_data_updated() -> void:
	_source.add_edge("A", "B")
	var emitted := false
	_source.data_updated.connect(func(_d: Dictionary) -> void: emitted = true)
	_source.remove_edge("A", "B")
	assert_bool(emitted).is_true()


func test_remove_nonexistent_edge_is_silent() -> void:
	_source.remove_edge("ghost", "node")  # must not throw
	assert_array(_source.get_data()["edges"]).is_empty()


# ---------------------------------------------------------------------------
# get_data isolation (no shared reference leaks)
# ---------------------------------------------------------------------------

func test_get_data_returns_independent_copy() -> void:
	_source.add_node("A")
	var d1: Dictionary = _source.get_data()
	_source.add_node("B")
	var d2: Dictionary = _source.get_data()
	assert_array(d1["nodes"]).has_size(1)
	assert_array(d2["nodes"]).has_size(2)
