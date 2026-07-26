extends SceneTree

const ChartDataset = preload("res://addons/godot-charts/charts_2d/chart_dataset_2d.gd")
const ChartData = preload("res://addons/godot-charts/charts_2d/chart_data_2d.gd")
const ChartPalette = preload("res://addons/godot-charts/charts_2d/chart_palette_2d.gd")
const LineChart = preload("res://addons/godot-charts/charts_2d/line_chart_2d.gd")

var _failures: PackedStringArray = []
var _change_count := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_data_range()
	_test_domain_behavior()
	_test_dataset_change_propagation()
	_test_palette_slots()
	_test_control_instantiation()
	if _failures.is_empty():
		print("Godot Charts 2D contract passed.")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)


func _test_data_range() -> void:
	var data = ChartData.new(PackedStringArray(["1", "2", "3"]), [
		ChartDataset.new("finite", PackedFloat32Array([2.0, NAN, 8.0])),
		ChartDataset.new("hidden", PackedFloat32Array([-100.0, 100.0])),
	])
	data.datasets[1].visible = false
	_expect(data.finite_value_range() == Vector2(2.0, 8.0),
		"Visible finite range must ignore hidden and non-finite values.")
	_expect(data.finite_value_range(false) == Vector2(-100.0, 100.0),
		"Unfiltered finite range must include hidden datasets.")
	var empty = ChartData.new(PackedStringArray(), [
		ChartDataset.new("empty", PackedFloat32Array([NAN, INF])),
	])
	_expect(empty.finite_value_range() == null,
		"All-non-finite data must return an empty range.")


func _test_domain_behavior() -> void:
	var ordinary = ChartData.new(PackedStringArray(["1", "2"]), [
		ChartDataset.new("ordinary", PackedFloat32Array([10.0, 20.0])),
	])
	var domain: Vector2 = LineChart.value_domain(ordinary)
	_expect(domain.x < 10.0 and domain.y > 20.0,
		"Ordinary domains must include deterministic visual padding.")
	var zero_domain: Vector2 = LineChart.value_domain(ordinary, true)
	_expect(zero_domain.x <= 0.0 and zero_domain.y > 20.0,
		"begin_at_zero must expand a positive domain through zero.")
	var constant = ChartData.new(PackedStringArray(["1", "2"]), [
		ChartDataset.new("constant", PackedFloat32Array([5.0, 5.0])),
	])
	var constant_domain: Vector2 = LineChart.value_domain(constant)
	_expect(constant_domain.x < 5.0 and constant_domain.y > 5.0,
		"Constant series must widen to a valid domain.")
	_expect(LineChart.value_domain(ChartData.new()) == null,
		"Empty chart data must have no value domain.")


func _test_dataset_change_propagation() -> void:
	var dataset = ChartDataset.new("series", PackedFloat32Array([1.0]))
	var data = ChartData.new(PackedStringArray(["1"]), [dataset])
	data.changed.connect(_on_data_changed)
	dataset.values = PackedFloat32Array([2.0])
	_expect(_change_count == 1,
		"Dataset mutation must invalidate its owning chart data exactly once.")


func _test_palette_slots() -> void:
	var palette = ChartPalette.new()
	var seen: Dictionary = {}
	for index in 8:
		seen[palette.series_color(index)] = true
	_expect(seen.size() == 8, "The first eight categorical colors must be distinct.")
	_expect(palette.series_color(8) == palette.series_color(7),
		"Palette overflow must clamp instead of silently reusing the first hue.")


func _test_control_instantiation() -> void:
	var chart = LineChart.new()
	chart.size = Vector2(640.0, 360.0)
	chart.chart_data = ChartData.new(PackedStringArray(["1", "2"]), [
		ChartDataset.new("series", PackedFloat32Array([1.0, 2.0])),
	])
	root.add_child(chart)
	_expect(chart is Control and chart.size == Vector2(640.0, 360.0),
		"LineChart2D must instantiate as a resizable Godot Control.")
	chart.queue_free()


func _on_data_changed() -> void:
	_change_count += 1


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
