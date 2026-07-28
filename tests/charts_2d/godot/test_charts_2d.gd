extends SceneTree

const ChartDataset = preload("res://addons/godot-charts/charts_2d/chart_dataset_2d.gd")
const ChartData = preload("res://addons/godot-charts/charts_2d/chart_data_2d.gd")
const ChartPalette = preload("res://addons/godot-charts/charts_2d/chart_palette_2d.gd")
const ChartReferenceLine = preload("res://addons/godot-charts/charts_2d/chart_reference_line_2d.gd")
const ChartAxis = preload("res://addons/godot-charts/charts_2d/chart_axis_2d.gd")
const LineChart = preload("res://addons/godot-charts/charts_2d/line_chart_2d.gd")

var _failures: PackedStringArray = []
var _change_count := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_data_range()
	_test_longitudinal_data_contract()
	_test_atomic_sample_append()
	_test_domain_behavior()
	_test_category_positions()
	_test_dataset_change_propagation()
	_test_palette_slots()
	_test_multiple_y_axes()
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


func _test_longitudinal_data_contract() -> void:
	var valid = ChartData.new(PackedStringArray(["D0", "D1"]), [
		ChartDataset.new("water", PackedFloat32Array([10.0, 8.0])),
		ChartDataset.new("air", PackedFloat32Array([90.0, 85.0])),
	])
	_expect(valid.validation_errors().is_empty(),
		"Aligned longitudinal data must validate.")

	var mismatched = ChartData.new(PackedStringArray(["D0", "D1"]), [
		ChartDataset.new("water", PackedFloat32Array([10.0])),
	])
	_expect(mismatched.validation_errors() == PackedStringArray([
		"Dataset 'water' has 1 values for 2 labels."]),
		"Mismatched series must report a deterministic alignment error.")

	var duplicates = ChartData.new(PackedStringArray(["D0", "D0"]), [
		ChartDataset.new("water", PackedFloat32Array([10.0, 8.0])),
		ChartDataset.new("water", PackedFloat32Array([90.0, 85.0])),
	])
	var duplicate_errors := duplicates.validation_errors()
	_expect(duplicate_errors.has("Duplicate category label 'D0' at index 1."),
		"Duplicate category labels must be rejected.")
	_expect(duplicate_errors.has("Duplicate dataset label 'water' at index 1."),
		"Duplicate dataset labels must be rejected.")


func _test_atomic_sample_append() -> void:
	var water = ChartDataset.new("water", PackedFloat32Array([10.0]))
	var air = ChartDataset.new("air", PackedFloat32Array([90.0]))
	var data = ChartData.new(PackedStringArray(["D0"]), [water, air])
	_change_count = 0
	data.changed.connect(_on_data_changed)

	var result: Error = data.append_sample("D1", {"water": 8.0})
	_expect(result == OK, "A valid sample append must succeed.")
	_expect(data.labels == PackedStringArray(["D0", "D1"]),
		"Atomic append must add the shared category label.")
	_expect(water.values == PackedFloat32Array([10.0, 8.0]),
		"Atomic append must add provided series values.")
	_expect(air.values.size() == 2 and is_nan(air.values[1]),
		"Missing series values must append as explicit NAN gaps.")
	_expect(_change_count == 1,
		"Atomic append must invalidate owning chart data exactly once.")

	var labels_before: PackedStringArray = data.labels.duplicate()
	var water_before: PackedFloat32Array = water.values.duplicate()
	result = data.append_sample("D1", {"water": 7.0})
	_expect(result == ERR_INVALID_DATA,
		"Duplicate categories must fail.")
	_expect(data.labels == labels_before and water.values == water_before,
		"A rejected duplicate category must not partially mutate data.")

	result = data.append_sample("D2", {"unknown": 1.0})
	_expect(result == ERR_INVALID_PARAMETER,
		"Unknown dataset keys must fail.")
	_expect(data.labels == labels_before and water.values == water_before,
		"A rejected unknown series must not partially mutate data.")


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
	_expect(LineChart.resolved_domain(
			ordinary, false, true, Vector2(-10.0, 10.0)) \
			== Vector2(-10.0, 10.0),
		"A valid explicit domain must override automatic scaling.")
	_expect(LineChart.resolved_domain(
			ordinary, false, true, Vector2(10.0, -10.0)) == domain,
		"An invalid explicit domain must fall back to automatic scaling.")
	var warning_lines: Array[Resource] = [
		ChartReferenceLine.new(50.0, "Warning")]
	var warned_domain: Vector2 = LineChart.domain_with_reference_lines(
		domain, warning_lines)
	_expect(warned_domain.x == domain.x and warned_domain.y == 50.0,
		"Visible reference lines must expand the chart domain.")


func _test_category_positions() -> void:
	_expect(LineChart.category_unit(0, 1) == 0.0,
		"A single sample must begin at the left origin.")
	_expect(LineChart.category_unit(0, 2) == 0.0 \
			and LineChart.category_unit(1, 2) == 1.0,
		"Two samples must span the full horizontal domain.")


func _test_dataset_change_propagation() -> void:
	var dataset = ChartDataset.new("series", PackedFloat32Array([1.0]))
	var data = ChartData.new(PackedStringArray(["1"]), [dataset])
	_change_count = 0
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


func _test_multiple_y_axes() -> void:
	var chart = LineChart.new()
	root.add_child(chart)
	var stock = ChartDataset.new(
		"Stock", PackedFloat32Array([8000.0, 7000.0]),
		Color.BLUE, &"stock")
	var ratio = ChartDataset.new(
		"Ratio", PackedFloat32Array([8.0, 4.0]),
		Color.GREEN, &"ratio")
	chart.chart_data = ChartData.new(
		PackedStringArray(["D1", "D2"]), [stock, ratio])
	var axes_config: Array[Resource] = [
		ChartAxis.new(&"stock", "L", ChartAxis.Side.LEFT, Color.BLUE),
		ChartAxis.new(&"ratio", "R", ChartAxis.Side.RIGHT, Color.GREEN),
	]
	chart.y_axes = axes_config
	var axes := chart._resolved_axes(ChartPalette.new())
	var domains := chart._axis_domains(axes)
	_expect(domains.size() == 2,
		"Each named Y axis must resolve an independent domain.")
	_expect(domains[&"stock"].x > 1000.0,
		"Large stock values must remain on the stock axis.")
	_expect(domains[&"ratio"].y < 10.0,
		"Small ratios must remain readable on their own axis.")
	var threshold = ChartReferenceLine.new(
		5.0, "Ratio threshold", Color.YELLOW, &"ratio")
	var threshold_lines: Array[Resource] = [threshold]
	chart.reference_lines = threshold_lines
	domains = chart._axis_domains(axes)
	_expect(domains[&"ratio"].x <= 4.0 and domains[&"ratio"].y >= 8.0,
		"Reference lines must participate only in their assigned axis.")
	chart.queue_free()


func _test_control_instantiation() -> void:
	var chart = LineChart.new()
	chart.size = Vector2(640.0, 360.0)
	chart.chart_data = ChartData.new(PackedStringArray(["1", "2"]), [
		ChartDataset.new("series", PackedFloat32Array([1.0, 2.0])),
	])
	chart.title = "Compact example"
	chart.compact_mode = true
	chart.content_inset_left = 24.0
	chart.show_legend = false
	root.add_child(chart)
	_expect(chart is Control and chart.size == Vector2(640.0, 360.0),
		"LineChart2D must instantiate as a resizable Godot Control.")
	chart.queue_free()


func _on_data_changed() -> void:
	_change_count += 1


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
