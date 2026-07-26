@tool
class_name LineChart2D
extends Control

## Resizable, multi-series 2D line chart for HUDs and SubViewport surfaces.

const LinearTicksScript = preload("../core/linear_ticks.gd")

var _chart_data: ChartData2D
var _palette: ChartPalette2D

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
@export var show_grid := true:
	set(value):
		show_grid = value
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
	var domain := value_domain(chart_data, begin_at_zero)
	if domain == null:
		_draw_empty(colors)
		return
	_draw_axes_and_grid(plot, domain, colors)
	_draw_series(plot, domain, colors)
	if show_legend:
		_draw_legend(colors)


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


func _plot_rect() -> Rect2:
	return Rect2(
		Vector2(plot_padding.x, plot_padding.y),
		Vector2(
			size.x - plot_padding.x - plot_padding.z,
			size.y - plot_padding.y - plot_padding.w
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


func _draw_segment(points: PackedVector2Array, color: Color) -> void:
	if points.size() >= 2:
		draw_polyline(points, color, line_width, true)
	if marker_radius > 0.0:
		for point in points:
			draw_circle(point, marker_radius, color)


func _draw_legend(colors: ChartPalette2D) -> void:
	if chart_data == null:
		return
	var x := plot_padding.x
	var y := 22.0
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
