extends GdUnitTestSuite

var _source: DictDataSource


func before_test() -> void:
	_source = auto_free(DictDataSource.new())


func test_get_data_default_is_empty() -> void:
	assert_dict(_source.get_data()).is_empty()


func test_get_data_returns_assigned_dict() -> void:
	var d := {
		"labels":   ["A", "B"],
		"datasets": [{"name": "S1", "values": [1.0, 2.0]}],
	}
	_source.source_data = d
	assert_dict(_source.get_data()).contains_keys(["labels", "datasets"])


func test_get_data_returns_exact_value() -> void:
	var d := {"labels": ["X"], "datasets": []}
	_source.source_data = d
	assert_dict(_source.get_data()).is_equal(d)


func test_source_data_setter_emits_signal() -> void:
	var emitted := false
	_source.data_updated.connect(func(_d: Dictionary) -> void: emitted = true)
	_source.source_data = {"labels": [], "datasets": []}
	assert_bool(emitted).is_true()


func test_signal_carries_new_data() -> void:
	var received: Dictionary = {}
	_source.data_updated.connect(func(d: Dictionary) -> void: received = d)
	var d := {"labels": ["Z"], "datasets": []}
	_source.source_data = d
	assert_dict(received).is_equal(d)


func test_reassigning_source_data_updates_get_data() -> void:
	_source.source_data = {"labels": ["A"], "datasets": []}
	_source.source_data = {"labels": ["B", "C"], "datasets": []}
	assert_array(_source.get_data()["labels"]).has_size(2)
