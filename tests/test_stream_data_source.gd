extends GdUnitTestSuite

var _stream: StreamDataSource


func before_test() -> void:
	_stream = auto_free(StreamDataSource.new())


# ---------------------------------------------------------------------------
# append_point — series creation and value storage
# ---------------------------------------------------------------------------

func test_append_point_creates_series() -> void:
	_stream.append_point("CPU", 50.0)
	assert_array(_stream.get_series_names()).contains(["CPU"])


func test_append_point_stores_value() -> void:
	_stream.append_point("CPU", 42.0)
	var values: Array = _stream.get_data()["datasets"][0]["values"]
	assert_float(float(values[0])).is_equal(42.0)


func test_append_point_multiple_series_created() -> void:
	_stream.append_point("CPU", 10.0)
	_stream.append_point("GPU", 20.0)
	assert_array(_stream.get_series_names()).has_size(2)


func test_append_point_series_order_preserved() -> void:
	_stream.append_point("A", 1.0)
	_stream.append_point("B", 2.0)
	_stream.append_point("C", 3.0)
	var names := _stream.get_series_names()
	assert_str(names[0]).is_equal("A")
	assert_str(names[1]).is_equal("B")
	assert_str(names[2]).is_equal("C")


# ---------------------------------------------------------------------------
# max_window / FIFO eviction
# ---------------------------------------------------------------------------

func test_append_point_respects_max_window() -> void:
	_stream.max_window = 3
	for i in 6:
		_stream.append_point("S", float(i))
	var values: Array = _stream.get_data()["datasets"][0]["values"]
	assert_array(values).has_size(3)


func test_append_point_fifo_oldest_dropped() -> void:
	_stream.max_window = 3
	for i in range(1, 5):  # pushes 1, 2, 3, 4 → window keeps 2, 3, 4
		_stream.append_point("S", float(i))
	var values: Array = _stream.get_data()["datasets"][0]["values"]
	assert_float(float(values[0])).is_equal(2.0)
	assert_float(float(values[1])).is_equal(3.0)
	assert_float(float(values[2])).is_equal(4.0)


# ---------------------------------------------------------------------------
# append_frame
# ---------------------------------------------------------------------------

func test_append_frame_creates_all_series() -> void:
	_stream.append_frame({"A": 1.0, "B": 2.0})
	assert_array(_stream.get_series_names()).has_size(2)


func test_append_frame_emits_once_per_call() -> void:
	# Signal fires once after all series are updated, not once per series.
	var emit_count := 0
	_stream.data_updated.connect(func(_d: Dictionary) -> void: emit_count += 1)
	_stream.append_frame({"X": 1.0, "Y": 2.0, "Z": 3.0})
	assert_int(emit_count).is_equal(1)


# ---------------------------------------------------------------------------
# get_data shape
# ---------------------------------------------------------------------------

func test_get_data_empty_returns_empty_dict() -> void:
	assert_dict(_stream.get_data()).is_empty()


func test_get_data_has_required_keys() -> void:
	_stream.append_point("S", 1.0)
	var data := _stream.get_data()
	assert_dict(data).contains_keys(["labels", "datasets"])


func test_get_data_labels_length_matches_values() -> void:
	for i in 5:
		_stream.append_point("S", float(i))
	var data := _stream.get_data()
	assert_array(data["labels"]).has_size(5)
	assert_array(data["datasets"][0]["values"]).has_size(5)


func test_get_data_dataset_has_name_and_values() -> void:
	_stream.append_point("MySeries", 7.0)
	var ds: Dictionary = _stream.get_data()["datasets"][0]
	assert_str(ds["name"]).is_equal("MySeries")
	assert_array(ds["values"]).has_size(1)


# ---------------------------------------------------------------------------
# data_updated signal
# ---------------------------------------------------------------------------

func test_append_point_emits_data_updated() -> void:
	var emitted := false
	_stream.data_updated.connect(func(_d: Dictionary) -> void: emitted = true)
	_stream.append_point("S", 1.0)
	assert_bool(emitted).is_true()


# ---------------------------------------------------------------------------
# clear_data
# ---------------------------------------------------------------------------

func test_clear_data_empties_buffers() -> void:
	_stream.append_point("S", 1.0)
	_stream.clear_data()
	assert_dict(_stream.get_data()).is_empty()


func test_clear_data_clears_series_names() -> void:
	_stream.append_point("S", 1.0)
	_stream.clear_data()
	assert_array(_stream.get_series_names()).has_size(0)


func test_clear_data_allows_new_series_after_clear() -> void:
	_stream.append_point("Old", 1.0)
	_stream.clear_data()
	_stream.append_point("New", 2.0)
	assert_array(_stream.get_series_names()).contains(["New"])
	assert_bool(_stream.get_series_names().has("Old")).is_false()
