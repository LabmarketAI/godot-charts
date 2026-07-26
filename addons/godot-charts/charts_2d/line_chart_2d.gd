@tool
class_name LineChart2D
extends Control

## Resizable, multi-series 2D line chart for HUDs and SubViewport surfaces.

const LinearTicksScript = preload("../core/linear_ticks.gd")
const ChartReferenceLine = preload("chart_reference_line_2d.gd")

var _chart_data: ChartData2D
var _palette: ChartPalette2D
var _reference_lines: Array[Resource] = []

@export var chart_data: ChartData2D:
	get:
		return _chart_data
	set(value):
		_set_chart_data(value)
@export var palette: ChartPalette2D:
	get:
		return _palette
	set(value):
		_set_palette(value)
@export var reference_lines: Array[Resource] = []:
	get:
		return _reference_lines
	set(value):
		_set_reference_lines(value)
@export var title := "":
	set(value):
		title = value
		queue_redraw()
@export var begin_at_zero := false:
	set(value):
		begin_at_zero = value
		queue_redraw()
@export_range(1.0, 12.0, 0.5) var line_width := 4.0:
	set(value):
		line_width = value
		queue_redraw()
@export_range(0.0, 16.0, 0.5) var marker_radius := 4.0:
	set(value):
		marker_radius = value
		queue_redraw()
@export var show_legend := true:
	set(value):
		show_legend = value
		queue_redraw()
@export var show_x_labels := true:
	set(value):
		show_x_labels = value
		queue_redraw()
@export var show_y_labels := true:
	set(value):
		show_y_labels = value
		queue_redraw()
@export var show_grid := true:
	set(value):
		show_grid = value
		queue_redraw()
@export var compact_mode := false:
	set(value):
		compact_mode = value
		queue_redraw()
@export var domain_override_enabled := false:
	set(value):
		domain_override_enabled = value
		queue_redraw()
@export var domain_override := Vector2(0.0, 1.0):
	set(value):
		domain_override = value
		queue_redraw()
@export_range(2, 12, 1) var x_label_target_count := 6:
	set(value):
		x_label_target_count = value
		queue_redraw()
@export_range(0.0, 512.0, 1.0) var content_inset_left := 0.0:
	set(value):
		content_inset_left = value
		queue_redraw()
@export var empty_text := "No samples yet":
	set(value):
		empty_text = value
		queue_redraw()
@export var plot_padding := Vector4(92.0, 40.0, 36.0, 64.0):
	set(value):
		plot_padding = value
		queue_redraw()


func _ready() -> void:
	resized.connect(queue_redraw)
	if palette == null:
		palette = ChartPalette2D.new()
	queue_redraw()


func _draw() -> void:
	var colors := palette if palette != null else ChartPalette2D.new()
	draw_rect(Rect2(Vector2.ZERO, size), colors.background)
	var plot := _plot_rect()
	if plot.size.x <= 0.0 or plot.size.y <= 0.0:
		return
	var domain := resolved_domain(
		chart_data,
		begin_at_zero,
		domain_override_enabled,
		domain_override)
	domain = domain_with_reference_lines(domain, reference_lines)
	if domain == null:
		_draw_empty(colors)
		return
	_draw_axes_and_grid(plot, domain, colors)
	_draw_reference_lines(plot, domain, colors)
	_draw_series(plot, domain, colors)
	_draw_header(colors)


static func value_domain(data: ChartData2D, include_zero: bool = false) -> Variant:
	if data == null:
		return null
	var raw: Variant = data.finite_value_range()
	if raw == null:
		return null
	var minimum: float = raw.x
	var maximum: float = raw.y
	if include_zero:
		minimum = minf(minimum, 0.0)
		maximum = maxf(maximum, 0.0)
	if is_equal_approx(minimum, maximum):
		var padding := maxf(absf(minimum) * 0.05, 1.0)
		minimum -= padding
		maximum += padding
	else:
		var padding := (maximum - minimum) * 0.05
		minimum -= padding
		maximum += padding
	return Vector2(minimum, maximum)


static func resolved_domain(
		data: ChartData2D,
		include_zero: bool = false,
		use_override: bool = false,
		override: Vector2 = Vector2.ZERO
) -> Variant:
	if use_override and is_finite(override.x) and is_finite(override.y) \
			and override.x < override.y:
		return override
	return value_domain(data, include_zero)


static func domain_with_reference_lines(
		domain: Variant,
		lines: Array[Resource]
) -> Variant:
	var result: Variant = domain
	for line in lines:
		if line == null or not is_finite(line.value):
			continue
		if result == null:
			result = Vector2(line.value - 1.0, line.value + 1.0)
		else:
			result = Vector2(
				minf(result.x, line.value),
				maxf(result.y, line.value))
	if result is Vector2 and is_equal_approx(result.x, result.y):
		result = Vector2(result.x - 1.0, result.y + 1.0)
	return result


func _plot_rect() -> Rect2:
	var padding := plot_padding
	if compact_mode:
		padding = Vector4(
			minf(plot_padding.x, 64.0),
			minf(plot_padding.y, 32.0),
			minf(plot_padding.z, 20.0),
			minf(plot_padding.w, 40.0))
	padding.x += content_inset_left
	return Rect2(
		Vector2(padding.x, padding.y),
		Vector2(
			size.x - padding.x - padding.z,
			size.y - padding.y - padding.w
		)
	)


func _draw_axes_and_grid(plot: Rect2, domain: Vector2, colors: ChartPalette2D) -> void:
	var ticks: Array[float] = LinearTicksScript.generate(domain.x, domain.y, 5)
	var step := ticks[1] - ticks[0] if ticks.size() > 1 else domain.y - domain.x
	for value in ticks:
		var unit := (value - domain.x) / (domain.y - domain.x)
		var y := lerpf(plot.end.y, plot.position.y, unit)
		if show_grid:
			draw_line(Vector2(plot.position.x, y), Vector2(plot.end.x, y), colors.grid, 1.0)
		if show_y_labels:
			draw_string(
				ThemeDB.fallback_font,
				Vector2(8.0, y + ThemeDB.fallback_font_size * 0.35),
				LinearTicksScript.format(value, step),
				HORIZONTAL_ALIGNMENT_RIGHT,
				plot.position.x - 16.0,
				ThemeDB.fallback_font_size,
				colors.foreground
			)
	draw_line(plot.position, Vector2(plot.position.x, plot.end.y), colors.foreground, 2.0)
	draw_line(Vector2(plot.position.x, plot.end.y), plot.end, colors.foreground, 2.0)
	if show_x_labels:
		_draw_x_labels(plot, colors)


func _draw_series(plot: Rect2, domain: Vector2, colors: ChartPalette2D) -> void:
	if chart_data == null:
		return
	var category_count := maxi(chart_data.labels.size(), _maximum_value_count())
	if category_count <= 0:
		return
	for series_index in chart_data.datasets.size():
		var dataset := chart_data.datasets[series_index]
		if dataset == null or not dataset.visible:
			continue
		var color := dataset.color if dataset.color.a > 0.0 else colors.series_color(series_index)
		var segment := PackedVector2Array()
		for value_index in dataset.values.size():
			var value := dataset.values[value_index]
			if not is_finite(value):
				_draw_segment(segment, color)
				segment.clear()
				continue
			var x_unit := 0.5 if category_count == 1 else float(value_index) / float(category_count - 1)
			var y_unit := (value - domain.x) / (domain.y - domain.x)
			segment.append(Vector2(
				lerpf(plot.position.x, plot.end.x, x_unit),
				lerpf(plot.end.y, plot.position.y, y_unit)
			))
		_draw_segment(segment, color)


func _draw_reference_lines(
		plot: Rect2,
		domain: Vector2,
		_colors: ChartPalette2D
) -> void:
	for line in reference_lines:
		if line == null or not is_finite(line.value):
			continue
		var unit := (float(line.value) - domain.x) / (domain.y - domain.x)
		var y := lerpf(plot.end.y, plot.position.y, unit)
		draw_line(
			Vector2(plot.position.x, y),
			Vector2(plot.end.x, y),
			line.color,
			line.width)
		if not line.label.is_empty():
			var label_y := clampf(
				y - 5.0,
				plot.position.y + ThemeDB.fallback_font_size,
				plot.end.y - 4.0)
			draw_string(
				ThemeDB.fallback_font,
				Vector2(plot.position.x + 8.0, label_y),
				line.label,
				HORIZONTAL_ALIGNMENT_LEFT,
				plot.size.x - 16.0,
				ThemeDB.fallback_font_size,
				line.color)


func _draw_segment(points: PackedVector2Array, color: Color) -> void:
	if points.size() >= 2:
		draw_polyline(points, color, line_width, true)
	if marker_radius > 0.0:
		for point in points:
			draw_circle(point, marker_radius, color)


func _draw_header(colors: ChartPalette2D) -> void:
	var x := (8.0 if compact_mode else plot_padding.x) + content_inset_left
	var y := 22.0
	if not title.is_empty():
		draw_string(
			ThemeDB.fallback_font,
			Vector2(x, y),
			title,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1.0,
			ThemeDB.fallback_font_size,
			colors.foreground
		)
		x += ThemeDB.fallback_font.get_string_size(
			title,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1.0,
			ThemeDB.fallback_font_size
		).x + 32.0
	if not show_legend or chart_data == null:
		return
	for index in chart_data.datasets.size():
		var dataset := chart_data.datasets[index]
		if dataset == null or not dataset.visible:
			continue
		var color := dataset.color if dataset.color.a > 0.0 else colors.series_color(index)
		draw_line(Vector2(x, y - 5.0), Vector2(x + 24.0, y - 5.0), color, line_width)
		draw_string(
			ThemeDB.fallback_font,
			Vector2(x + 32.0, y),
			dataset.label,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1.0,
			ThemeDB.fallback_font_size,
			colors.foreground
		)
		x += 48.0 + ThemeDB.fallback_font.get_string_size(
			dataset.label,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1.0,
			ThemeDB.fallback_font_size
		).x


func _draw_x_labels(plot: Rect2, colors: ChartPalette2D) -> void:
	if chart_data == null or chart_data.labels.is_empty():
		return
	var count := chart_data.labels.size()
	var target := mini(maxi(x_label_target_count, 2), count)
	var stride := maxi(ceili(float(count - 1) / float(target - 1)), 1) \
		if count > 1 else 1
	var indices: Array[int] = []
	for index in range(0, count, stride):
		indices.append(index)
	if indices[-1] != count - 1:
		indices.append(count - 1)
	for index in indices:
		var x_unit := 0.5 if count == 1 else float(index) / float(count - 1)
		var x := lerpf(plot.position.x, plot.end.x, x_unit)
		var label := chart_data.labels[index]
		var width := ThemeDB.fallback_font.get_string_size(
			label,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1.0,
			ThemeDB.fallback_font_size
		).x
		draw_string(
			ThemeDB.fallback_font,
			Vector2(x - width * 0.5, plot.end.y + ThemeDB.fallback_font_size + 8.0),
			label,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1.0,
			ThemeDB.fallback_font_size,
			colors.foreground
		)


func _draw_empty(colors: ChartPalette2D) -> void:
	draw_string(
		ThemeDB.fallback_font,
		Vector2(0.0, size.y * 0.5),
		empty_text,
		HORIZONTAL_ALIGNMENT_CENTER,
		size.x,
		ThemeDB.fallback_font_size * 1.5,
		colors.foreground
	)


func _maximum_value_count() -> int:
	var result := 0
	if chart_data != null:
		for dataset in chart_data.datasets:
			if dataset != null and dataset.visible:
				result = maxi(result, dataset.values.size())
	return result


func _set_chart_data(value: ChartData2D) -> void:
	if _chart_data != null and _chart_data.changed.is_connected(queue_redraw):
		_chart_data.changed.disconnect(queue_redraw)
	_chart_data = value
	if _chart_data != null and not _chart_data.changed.is_connected(queue_redraw):
		_chart_data.changed.connect(queue_redraw)
	queue_redraw()


func _set_palette(value: ChartPalette2D) -> void:
	if _palette != null and _palette.changed.is_connected(queue_redraw):
		_palette.changed.disconnect(queue_redraw)
	_palette = value
	if _palette != null and not _palette.changed.is_connected(queue_redraw):
		_palette.changed.connect(queue_redraw)
	queue_redraw()


func _set_reference_lines(value: Array[Resource]) -> void:
	for line in _reference_lines:
		if line != null and line.changed.is_connected(queue_redraw):
			line.changed.disconnect(queue_redraw)
	_reference_lines = value
	for line in _reference_lines:
		if line != null and not line.changed.is_connected(queue_redraw):
			line.changed.connect(queue_redraw)
	queue_redraw()
